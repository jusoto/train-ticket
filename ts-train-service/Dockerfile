# FROM openjdk:8-jre

# # RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

# ADD ./target/ts-train-service-1.0.jar /app/
# CMD ["java", "-Xmx200m",  "-jar", "/app/ts-train-service-1.0.jar"]

# EXPOSE 14567

FROM ubuntu:22.04
LABEL MAINTAINER="Juan P. Sotomayor jsoto128@fiu.edu"
RUN apt-get update && apt-get install -y openjdk-8-jdk apt-transport-https gnupg2 curl lsb-release
ADD https://github.com/envoyproxy/envoy/releases/download/v1.29.3/envoy-1.29.3-linux-x86_64 /usr/local/bin/envoy
RUN chmod +x /usr/local/bin/envoy
RUN mkdir /app
COPY . /app
WORKDIR /app
VOLUME /tmp
ADD ./target/ts-train-service-1.0.jar /app/
COPY envoy.yaml /etc/envoy/envoy.yaml
RUN chmod go+r /etc/envoy/envoy.yaml
ENV JAVA_OPTS="-Xmx200m"
EXPOSE 14567
ENTRYPOINT [ "sh", "-c", "/usr/local/bin/envoy -c /etc/envoy/envoy.yaml & java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app/ts-train-service-1.0.jar" ]