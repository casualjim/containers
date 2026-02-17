import process from "node:process";
import { diag, DiagConsoleLogger, DiagLogLevel } from "@opentelemetry/api";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-grpc";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-grpc";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { PeriodicExportingMetricReader } from "@opentelemetry/sdk-metrics";

const collectorAddress = process.env.OTEL_COLLECTOR_ADDR ?? "signoz-otel-collector.signoz.svc:4317";
const serviceName = process.env.OTEL_SERVICE_NAME ?? "fission-bun-env";

const endpoint = collectorAddress.startsWith("http://") || collectorAddress.startsWith("https://")
  ? collectorAddress
  : `http://${collectorAddress}`;

if (process.env.OTEL_DIAG_LOG === "true") {
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
