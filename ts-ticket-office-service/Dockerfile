# FROM node

# # RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

# RUN mkdir -p /app
# WORKDIR /app

# ADD ./node_modules /app/node_modules
# ADD ./package.json /app/
# ADD ./public /app/public
# # RUN npm install

# ADD ./bin /app/bin
# ADD ./app.js /app/
# CMD [ "npm", "start" ]

# EXPOSE 16108

FROM ubuntu:22.04
LABEL MAINTAINER="Juan P. Sotomayor jsoto128@fiu.edu"
RUN apt-get update && apt-get install -y node apt-transport-https gnupg2 curl lsb-release
ADD https://github.com/envoyproxy/envoy/releases/download/v1.29.3/envoy-1.29.3-linux-x86_64 /usr/local/bin/envoy
RUN chmod +x /usr/local/bin/envoy

RUN mkdir -p /app
WORKDIR /app

ADD ./node_modules /app/node_modules
ADD ./package.json /app/
ADD ./public /app/public
# RUN npm install

ADD ./bin /app/bin
ADD ./app.js /app/

COPY envoy.yaml /etc/envoy/envoy.yaml
RUN chmod go+r /etc/envoy/envoy.yaml

EXPOSE 16108

ENTRYPOINT [ "sh", "-c", "/usr/local/bin/envoy -c /etc/envoy/envoy.yaml & npm start" ]