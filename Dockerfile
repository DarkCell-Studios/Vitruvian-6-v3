FROM eclipse-temurin:11-jre

ENV CANTALOUPE_VERSION=6.0.0 \
    CANTALOUPE_HOME=/opt/cantaloupe

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --shell /bin/bash cantaloupe

WORKDIR /opt

RUN curl -L -o cantaloupe.zip https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip \
    && unzip cantaloupe.zip \
    && rm cantaloupe.zip \
    && ln -s /opt/cantaloupe-${CANTALOUPE_VERSION} ${CANTALOUPE_HOME}

COPY cantaloupe.properties /etc/cantaloupe/cantaloupe.properties
COPY delegates.rb /etc/cantaloupe/delegates.rb

RUN mkdir -p /var/cache/cantaloupe/source /var/cache/cantaloupe/derivative \
    && chown -R cantaloupe:cantaloupe /etc/cantaloupe /var/cache/cantaloupe /opt/cantaloupe-${CANTALOUPE_VERSION}

USER cantaloupe

EXPOSE 8182

ENTRYPOINT ["sh", "-c", "exec java -Xmx4g -Dcantaloupe.config=/etc/cantaloupe/cantaloupe.properties -jar $CANTALOUPE_HOME/cantaloupe-$CANTALOUPE_VERSION.war"]
