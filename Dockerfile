FROM python:3.14-slim-bookworm

LABEL maintainer="Lev Pasichnyi"
LABEL description="Production-ready Python server container"
LABEL licenses="MIT"
LABEL documentation="https://github.com/levarc-hub/python-try"

ARG VERSION
ARG COMMIT
ARG BUILD_DATE
ARG REPO

LABEL version=$VERSION \
  commit=$COMMIT \
  build_date=$BUILD_DATE \
  repo="https://github.com/${REPO}" \
  registry="ghcr.io/${REPO}"

ENV VERSION=$VERSION \
  COMMIT=$COMMIT \
  BUILD_DATE=$BUILD_DATE

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