#!/usr/bin/env bash
set -e

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
opentelemetry-bootstrap -a install

OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:8200" \
OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer <your_secret_token>" \
OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
OTEL_RESOURCE_ATTRIBUTES="service.name=tomo-apm-test,service.version=0.0.1,deployment.environment=my-environment" \
OTEL_PYTHON_LOG_LEVEL="debug" \
OTEL_LOGS_EXPORTER="none" \
opentelemetry-instrument python app.py
