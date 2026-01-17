FROM python:3.14-slim-bookworm

ARG VERSION
ARG COMMIT
ARG BUILD_DATE
ARG REPO

LABEL org.opencontainers.image.authors="Lev Pasichnyi <lev.pa@levarc.com>"
LABEL org.opencontainers.image.vendor="LEVARC™"
LABEL org.opencontainers.image.description="Python server container"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Python Template"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$COMMIT
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.source="https://github.com/${REPO}"
LABEL org.opencontainers.image.documentation="https://github.com/${REPO}"

ENV VERSION=$VERSION
ENV COMMIT=$COMMIT
ENV BUILD_DATE=$BUILD_DATE

WORKDIR /app
RUN useradd -m appuser
USER appuser

COPY src/requirements.txt ./requirements.txt
RUN grep -E '==' requirements.txt || (echo "Unpinned dependencies found!" && exit 1)
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["python", "src/server.py"]
