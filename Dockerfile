ARG DEPCHECK_TAG=8.0.2

FROM ghcr.io/gautaz/h2database:2.1.x-4 as base

FROM base as build
ARG DEPCHECK_TAG
USER root
RUN cd /usr/lib/jvm && ln -s java-8-amazon-corretto/lib
RUN apk add --no-cache git maven
RUN git clone --branch v$DEPCHECK_TAG --depth 1 https://github.com/jeremylong/DependencyCheck.git
WORKDIR /DependencyCheck
RUN mvn -s settings.xml  -D maven.test.skip -pl :dependency-check-core package

FROM base
ARG DEPCHECK_TAG
ARG H2_DATABASE=~/databases/dependency-check
ARG H2_USER=dc
ENV H2_DATABASE=$H2_DATABASE
ENV H2_USER=$H2_USER
COPY --from=build /DependencyCheck/core/target/dependency-check-core-$DEPCHECK_TAG.jar /opt/h2database/dependency-check-core.jar
COPY --from=build /DependencyCheck/core/src/main/resources/data/initialize.sql /opt/h2database/
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-web", "-webAllowOthers", "-tcp", "-tcpAllowOthers"]
HEALTHCHECK --interval=10s \
	CMD sh -c "[ "$(cat ~/h2.status)" = "STARTED" ] && /usr/bin/java -cp '/opt/h2database/h2.jar:/opt/h2database/dependency-check-core.jar' org.h2.tools.Shell -url \"jdbc:h2:tcp://localhost/$H2_DATABASE\" -user \"$H2_USER\" -password \"$H2_PASSWD\" -sql 'SELECT 1;'"
