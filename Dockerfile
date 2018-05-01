FROM ruby:alpine

RUN apk upgrade --update && \
    apk add --no-cache git libffi build-base zlib g++ ncurses readline yaml sqlite-dev ca-certificates \
        tzdata libxml2-dev && \
    mkdir -p /app
WORKDIR /app
COPY . /app/
RUN bundle install