FROM python:3.12-slim

WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt && opentelemetry-bootstrap -a install
EXPOSE 8080

ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://host.docker.internal:8200"
ENV OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer df3868c077f75491589aab07b3d24345"
ENV OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
ENV OTEL_RESOURCE_ATTRIBUTES="service.name=tomo-apm-test,service.version=0.0.1,deployment.environment=my-environment"
ENV OTEL_PYTHON_LOG_LEVEL="debug"
ENV OTEL_LOGS_EXPORTER="none"

CMD ["opentelemetry-instrument", "python", "app.py"]
