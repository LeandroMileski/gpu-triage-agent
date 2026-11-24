FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/v1.36.0/bin/linux/amd64/kubectl \
    && chmod 0755 /usr/local/bin/kubectl \
    && apt-get purge -y curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY diagnose.py /app/diagnose.py

USER 65532:65532
ENTRYPOINT ["python", "/app/diagnose.py"]
