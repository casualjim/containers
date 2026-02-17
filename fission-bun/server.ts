const isTruthy = (value: string | undefined): boolean => {
  if (!value) {
    return false;
  }

  const normalized = value.trim().toLowerCase();
  return normalized === "1" || normalized === "true" || normalized === "yes" || normalized === "on";
};

const env = Bun.env;
const otelEnabled = (env.OTEL_ENABLED ?? "true").trim().toLowerCase() !== "false";

if (otelEnabled) {
  await import("./telemetry.ts");
}

const [{ default: pino }, fs, path] = await Promise.all([import("pino"), import("node:fs"), import("node:path")]);

type Logger = ReturnType<typeof pino>;
type InvocationResponse = {
  status: number;
  body?: unknown;
  headers?: HeadersInit;
};

type InvocationContext = {
  request: Request;
  logger: Logger;
};

type InvokeCallback = (status?: number, body?: unknown, headers?: HeadersInit) => void;
type UserFunction = (context: InvocationContext, callback?: InvokeCallback) => unknown;

type V2SpecializeRequest = {
  filepath?: string;
  functionName?: string;
};

const loggerOptions: Record<string, unknown> = {
  level: env.LOG_LEVEL ?? "info",
};

if (isTruthy(env.LOG_PRETTY)) {
  loggerOptions.transport = {
    target: "pino-pretty",
    options: {
      colorize: true,
      singleLine: true,
      translateTime: "SYS:standard",
    },
  };
}

const logger = pino(loggerOptions);

const SUPPORTED_EXTENSIONS = [".ts", ".js", ".mjs", ".cjs"];
const DEFAULT_V1_MODULE_PATH = "/userfunc/user";
const APP_NODE_MODULES = "/app/node_modules";
const USERFUNC_DIR = "/userfunc";
const USERFUNC_NODE_MODULES = "/userfunc/node_modules";

let userFunction: UserFunction | null = null;
let specializedPath: string | null = null;

const pathExists = (candidatePath: string): boolean => {
  try {
    fs.lstatSync(candidatePath);
    return true;
  } catch {
    return false;
  }
};

const fileExists = async (candidatePath: string): Promise<boolean> => {
  return Bun.file(candidatePath).exists();
};

const resolveWithExtensions = async (candidatePath: string): Promise<string> => {
  if (path.extname(candidatePath) !== "") {
    if (await fileExists(candidatePath)) {
      return candidatePath;
    }

    throw new Error(`Module file does not exist: ${candidatePath}`);
  }

  for (const extension of SUPPORTED_EXTENSIONS) {
    const withExtension = `${candidatePath}${extension}`;
    if (await fileExists(withExtension)) {
      return withExtension;
    }
  }

  throw new Error(`Could not resolve module with supported extensions: ${candidatePath}`);
};

const listSupportedFiles = async (directoryPath: string): Promise<string[]> => {
  const glob = new Bun.Glob("*.{ts,js,mjs,cjs}");
  const files: string[] = [];

  for await (const match of glob.scan({ cwd: directoryPath, onlyFiles: true })) {
    files.push(match);
  }

  files.sort();
  return files;
};

const resolveDirectoryEntrypoint = async (directoryPath: string): Promise<string> => {
  const packageJsonPath = path.join(directoryPath, "package.json");

  if (await fileExists(packageJsonPath)) {
    try {
      const packageJson = (await Bun.file(packageJsonPath).json()) as { main?: string };
      if (typeof packageJson.main === "string" && packageJson.main.trim() !== "") {
        const mainPath = path.resolve(directoryPath, packageJson.main);
        try {
          return await resolveWithExtensions(mainPath);
        } catch {
          // Fall through to conventional entrypoint lookup.
        }
      }
    } catch {
      // Ignore invalid package.json.
    }
  }

  for (const baseName of ["index", "user", "main"]) {
    try {
      return await resolveWithExtensions(path.join(directoryPath, baseName));
    } catch {
      // Try next candidate.
    }
  }

  const candidates = await listSupportedFiles(directoryPath);
  if (candidates.length > 0) {
    return path.join(directoryPath, candidates[0]);
  }

  throw new Error(`No supported module files found in ${directoryPath}`);
};

const resolveModulePath = async (inputPath: string): Promise<string> => {
  const absolutePath = path.isAbsolute(inputPath) ? inputPath : path.resolve(inputPath);

  if (!pathExists(absolutePath)) {
    return resolveWithExtensions(absolutePath);
  }

  const stats = fs.statSync(absolutePath);
  if (stats.isDirectory()) {
    return resolveDirectoryEntrypoint(absolutePath);
  }

  return absolutePath;
};

const ensureUserFuncNodeModulesSymlink = (): void => {
  if (pathExists(USERFUNC_NODE_MODULES)) {
    return;
  }

  if (!pathExists(USERFUNC_DIR) || !pathExists(APP_NODE_MODULES)) {
    return;
  }

  try {
    fs.symlinkSync(APP_NODE_MODULES, USERFUNC_NODE_MODULES, "dir");
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code !== "EEXIST") {
      logger.warn({ err: error }, "Failed to create /userfunc/node_modules symlink");
    }
  }
};

const selectUserExport = (userModule: Record<string, unknown>, functionName?: string): UserFunction => {
  if (functionName) {
    const named =
      userModule[functionName] ?? (userModule.default as Record<string, unknown> | undefined)?.[functionName];
    if (typeof named === "function") {
      return named as UserFunction;
    }

    throw new Error(`Export '${functionName}' was not found or is not a function`);
  }

  if (typeof userModule.default === "function") {
    return userModule.default as UserFunction;
  }

  const exportedFunctions = Object.values(userModule).filter(
    (value): value is UserFunction => typeof value === "function",
  );

  if (exportedFunctions.length === 1) {
    return exportedFunctions[0];
  }

  throw new Error("No callable default export found");
};

const loadFunction = async (
  modulePathInput: string,
  functionName?: string,
): Promise<{ fn: UserFunction; modulePath: string }> => {
  ensureUserFuncNodeModulesSymlink();

  const modulePath = await resolveModulePath(modulePathInput);
  const userModule = (await import(modulePath)) as Record<string, unknown>;
  const fn = selectUserExport(userModule, functionName);

  return { fn, modulePath };
};

const parseV2SpecializeRequest = async (request: Request): Promise<{ modulePath: string; functionName?: string }> => {
  const body = (await request.json()) as V2SpecializeRequest;

  const filepath = body.filepath?.trim() || USERFUNC_DIR;
  const functionName = body.functionName?.trim();

  if (!functionName) {
    return { modulePath: filepath };
  }

  if (functionName.includes(".")) {
    const separator = functionName.lastIndexOf(".");
    const filePart = functionName.slice(0, separator);
    const exportName = functionName.slice(separator + 1);

    if (filePart) {
      return {
        modulePath: path.join(filepath, filePart),
        functionName: exportName || undefined,
      };
    }
  }

  const absoluteFilepath = path.isAbsolute(filepath) ? filepath : path.resolve(filepath);

  if (pathExists(absoluteFilepath) && fs.statSync(absoluteFilepath).isDirectory()) {
    try {
      const resolvedAsFile = await resolveWithExtensions(path.join(absoluteFilepath, functionName));
      return { modulePath: resolvedAsFile };
    } catch {
      return { modulePath: filepath, functionName };
    }
  }

  return { modulePath: filepath, functionName };
};

const asResponseBody = (body: unknown, headers: Headers): BodyInit | null => {
  if (body === null || body === undefined) {
    return null;
  }

  if (
    typeof body === "string" ||
    body instanceof Blob ||
    body instanceof FormData ||
    body instanceof URLSearchParams ||
    body instanceof ArrayBuffer ||
    ArrayBuffer.isView(body) ||
    body instanceof ReadableStream
  ) {
    return body as BodyInit;
  }

  if (typeof body === "object") {
    if (!headers.has("content-type")) {
      headers.set("content-type", "application/json");
    }
    return JSON.stringify(body);
  }

  return String(body);
};

const buildResponse = (status: number, body?: unknown, headers?: HeadersInit): Response => {
  const responseHeaders = new Headers(headers);
  const responseBody = asResponseBody(body, responseHeaders);
  return new Response(responseBody, { status, headers: responseHeaders });
};

const normalizeInvocationResult = (result: unknown): Response => {
  if (result instanceof Response) {
    return result;
  }

  if (!result || typeof result !== "object") {
    throw new Error("User function must return Response or { status, body, headers }");
  }

  const typed = result as InvocationResponse;
  if (typeof typed.status !== "number") {
    throw new Error("User function result must include numeric status");
  }

  return buildResponse(typed.status, typed.body, typed.headers);
};

const invokeFunction = async (request: Request): Promise<Response> => {
  if (!userFunction) {
    return new Response("Not specialized", { status: 500 });
  }

  const context: InvocationContext = { request, logger };

  if (userFunction.length <= 1) {
    const result = await Promise.resolve(userFunction(context));
    return normalizeInvocationResult(result);
  }

  return new Promise<Response>((resolve, reject) => {
    let settled = false;

    const callback: InvokeCallback = (status?: number, body?: unknown, headers?: HeadersInit) => {
      if (settled) {
        return;
      }
      settled = true;

      if (typeof status !== "number") {
        resolve(new Response(null, { status: 204 }));
        return;
      }

      resolve(buildResponse(status, body, headers));
    };

    try {
      const maybeResult = userFunction(context, callback);
      if (maybeResult && typeof (maybeResult as Promise<unknown>).then === "function") {
        (maybeResult as Promise<unknown>)
          .then((resolvedResult) => {
            if (!settled && resolvedResult !== undefined) {
              settled = true;
              resolve(normalizeInvocationResult(resolvedResult));
            }
          })
          .catch((error) => {
            if (!settled) {
              settled = true;
              reject(error);
            }
          });
      }
    } catch (error) {
      reject(error);
    }
  });
};

const specialize = async (modulePath: string, functionName?: string): Promise<Response> => {
  if (userFunction) {
    return new Response("Not a generic container", { status: 400 });
  }

  try {
    const { fn, modulePath: resolvedModulePath } = await loadFunction(modulePath, functionName);
    userFunction = fn;
    specializedPath = resolvedModulePath;
    logger.info({ modulePath: resolvedModulePath, functionName }, "Container specialized");
    return new Response(null, { status: 202 });
  } catch (error) {
    logger.error({ err: error, modulePath, functionName }, "Specialization failed");
    const message = error instanceof Error ? error.message : "Unknown specialization error";
    return new Response(message, { status: 500 });
  }
};

const handleSpecializeV1 = async (): Promise<Response> => {
  return specialize(DEFAULT_V1_MODULE_PATH);
};

const handleSpecializeV2 = async (request: Request): Promise<Response> => {
  try {
    const { modulePath, functionName } = await parseV2SpecializeRequest(request);
    return specialize(modulePath, functionName);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid specialize request";
    logger.error({ err: error }, "Invalid v2 specialize request");
    return new Response(message, { status: 500 });
  }
};

const server = Bun.serve({
  port: 8888,
  fetch: async (request) => {
    const start = Date.now();
    const url = new URL(request.url);

    try {
      if (request.method === "POST" && url.pathname === "/specialize") {
        const response = await handleSpecializeV1();
        logger.info(
          { method: request.method, path: url.pathname, status: response.status, durationMs: Date.now() - start },
          "HTTP request",
        );
        return response;
      }

      if (request.method === "POST" && url.pathname === "/v2/specialize") {
        const response = await handleSpecializeV2(request);
        logger.info(
          { method: request.method, path: url.pathname, status: response.status, durationMs: Date.now() - start },
          "HTTP request",
        );
        return response;
      }

      const response = await invokeFunction(request);
      logger.info(
        {
          method: request.method,
          path: url.pathname,
          status: response.status,
          durationMs: Date.now() - start,
          specializedPath,
        },
        "HTTP request",
      );
      return response;
    } catch (error) {
      logger.error({ err: error, method: request.method, path: url.pathname }, "Request failed");
      return new Response("Internal server error", { status: 500 });
    }
  },
});

logger.info({ port: server.port, otelEnabled }, "Fission Bun environment listening");
