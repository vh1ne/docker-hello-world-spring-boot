# Maven build container 

# FROM maven:3.8.7-amazoncorretto-17 AS maven_build

# COPY pom.xml /tmp/

# COPY src /tmp/src/

# WORKDIR /tmp/

# RUN mvn package

# #pull base image

# FROM openjdk

# #maintainer 
# MAINTAINER vh1ne
# #expose port 8080
# EXPOSE 8080

# #default command
# CMD java -jar /data/hello-world-0.1.0.jar

# #copy hello world to docker image from builder image

# COPY --from=maven_build /tmp/target/hello-world-0.1.0.jar /data/hello-world-0.1.0.jar
FROM ghcr.io/graalvm/graalvm-ce:ol7-java17-22.3.0-b2

ADD . /build
WORKDIR /build

# For SDKMAN to work we need unzip & zip
RUN yum install -y unzip zip

RUN \
    # Install SDKMAN
    curl -s "https://get.sdkman.io" | bash; \
    source "$HOME/.sdkman/bin/sdkman-init.sh"; \
    sdk install maven; \
    # Install GraalVM Native Image
    gu install native-image;

RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && mvn --version

RUN native-image --version

RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && mvn clean package -Pnative 


# We use a Docker multi-stage build here in order that we only take the compiled native Spring Boot App from the first build container
FROM oraclelinux:9-slim

MAINTAINER v

# Add Spring Boot Native app hello-world to Container
COPY --from=0 "/build/target/hello-world" hello-world

# Fire up our Spring Boot Native app by default
CMD [ "sh", "-c", "./hello-world -Dserver.port=$PORT" ]