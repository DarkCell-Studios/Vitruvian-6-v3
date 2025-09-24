FROM eclipse-temurin:11-jre

ARG CANTALOUPE_VERSION=6.0.0
ARG CANTALOUPE_DOWNLOAD_URL=https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip
ARG CANTALOUPE_FALLBACK_URL=https://repo1.maven.org/maven2/edu/illinois/library/cantaloupe/${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip

ENV CANTALOUPE_VERSION=${CANTALOUPE_VERSION} \
    CANTALOUPE_HOME=/opt/cantaloupe

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --shell /bin/bash cantaloupe

WORKDIR /opt

RUN set -eux; \
    curl -fSL "${CANTALOUPE_DOWNLOAD_URL}" -o cantaloupe.zip \
    || { [ -n "${CANTALOUPE_FALLBACK_URL}" ] && curl -fSL "${CANTALOUPE_FALLBACK_URL}" -o cantaloupe.zip; } \
    || { echo "Unable to download Cantaloupe distribution" >&2; exit 1; }; \
    unzip -q cantaloupe.zip; \
    rm cantaloupe.zip; \
    ln -s /opt/cantaloupe-${CANTALOUPE_VERSION} "${CANTALOUPE_HOME}"

RUN mkdir -p /etc/cantaloupe

COPY cantaloupe.properties /etc/cantaloupe/cantaloupe.properties
COPY delegates.rb /etc/cantaloupe/delegates.rb

RUN mkdir -p /var/cache/cantaloupe/source /var/cache/cantaloupe/derivative \
    && chown -R cantaloupe:cantaloupe /etc/cantaloupe /var/cache/cantaloupe /opt/cantaloupe-${CANTALOUPE_VERSION}

USER cantaloupe

EXPOSE 8182

ENTRYPOINT ["sh", "-c", "exec java -Xmx4g -Dcantaloupe.config=/etc/cantaloupe/cantaloupe.properties -jar ${CANTALOUPE_HOME}/cantaloupe-${CANTALOUPE_VERSION}.war"]
