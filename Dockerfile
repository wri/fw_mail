FROM node:12-alpine
MAINTAINER info@vizzuality.com

ENV NAME gfw-mail-api
ENV USER microservice

RUN addgroup $USER && adduser -s /bin/bash -D -G $USER $USER

RUN apk update && apk upgrade && \
    apk add --no-cache --update bash git openssh python3 build-base

RUN yarn global add grunt-cli bunyan

RUN mkdir -p /opt/$NAME
COPY package.json /opt/$NAME/package.json
COPY yarn.lock /opt/$NAME/yarn.lock
COPY .eslintrc /opt/$NAME/.eslintrc
RUN cd /opt/$NAME && yarn

COPY config /opt/$NAME/config

WORKDIR /opt/$NAME

COPY ./app /opt/$NAME/app

RUN chown -R $USER:$USER /opt/$NAME

# Tell Docker we are going to use this ports
EXPOSE 3500
USER $USER

CMD node app/index.js
