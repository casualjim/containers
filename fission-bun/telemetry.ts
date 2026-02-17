import { DiagConsoleLogger, DiagLogLevel, diag } from "@opentelemetry/api";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-grpc";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-grpc";
import { PeriodicExportingMetricReader } from "@opentelemetry/sdk-metrics";
import { NodeSDK } from "@opentelemetry/sdk-node";

const env = Bun.env;
const collectorAddress = env.OTEL_COLLECTOR_ADDR ?? "signoz-otel-collector.signoz.svc:4317";
const serviceName = env.OTEL_SERVICE_NAME ?? "fission-bun-env";

const endpoint =
  collectorAddress.startsWith("http://") || collectorAddress.startsWith("https://")
    ? collectorAddress
    : `http://${collectorAddress}`;

if (env.OTEL_DIAG_LOG === "true") {
  diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.INFO);
}

const sdk = new NodeSDK({
  serviceName,
  traceExporter: new OTLPTraceExporter({ url: endpoint }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({ url: endpoint }),
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      "@opentelemetry/instrumentation-fs": {
        enabled: false,
      },
    }),
  ],
});

await sdk.start();

const shutdown = async () => {
  try {
    await sdk.shutdown();
  } catch {
    // Ignore telemetry shutdown errors.
  }
};

process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
