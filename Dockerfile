FROM eclipse-temurin:11-jre

ARG CANTALOUPE_VERSION=6.0.0
ARG CANTALOUPE_PRIMARY_URL=https://repo1.maven.org/maven2/edu/illinois/library/cantaloupe/${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip
ARG CANTALOUPE_FALLBACK_URL=https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip

ENV CANTALOUPE_VERSION=${CANTALOUPE_VERSION} \
    CANTALOUPE_HOME=/opt/cantaloupe

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --shell /bin/bash cantaloupe

WORKDIR /opt

RUN set -eux; \
    tmpdir="$(mktemp -d)"; \
    cd "${tmpdir}"; \
    success=0; \
    for url in "${CANTALOUPE_PRIMARY_URL}" "${CANTALOUPE_FALLBACK_URL}"; do \
        if [ -z "${url}" ]; then continue; fi; \
        if curl -fSL "${url}" -o cantaloupe.zip; then \
            if unzip -tq cantaloupe.zip > /dev/null 2>&1; then \
                success=1; \
                break; \
            fi; \
        fi; \
        rm -f cantaloupe.zip; \
    done; \
    if [ "${success}" -ne 1 ]; then \
        echo "Unable to download a valid Cantaloupe distribution" >&2; \
        exit 1; \
    fi; \
    unzip -q cantaloupe.zip -d /opt; \
    rm cantaloupe.zip; \
    ln -s /opt/cantaloupe-${CANTALOUPE_VERSION} "${CANTALOUPE_HOME}"; \
    cd /opt; \
    rm -rf "${tmpdir}"

RUN mkdir -p /etc/cantaloupe

COPY cantaloupe.properties /etc/cantaloupe/cantaloupe.properties
COPY delegates.rb /etc/cantaloupe/delegates.rb

RUN mkdir -p /var/cache/cantaloupe/source /var/cache/cantaloupe/derivative \
    && chown -R cantaloupe:cantaloupe /etc/cantaloupe /var/cache/cantaloupe /opt/cantaloupe-${CANTALOUPE_VERSION}

USER cantaloupe

EXPOSE 8182

ENTRYPOINT ["sh", "-c", "exec java -Xmx4g -Dcantaloupe.config=/etc/cantaloupe/cantaloupe.properties -jar ${CANTALOUPE_HOME}/cantaloupe-${CANTALOUPE_VERSION}.war"]
