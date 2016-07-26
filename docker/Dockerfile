FROM ubuntu:14.04

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -q -y install wget git libexpat1-dev gcc \
  && wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
  && dpkg -i erlang-solutions_1.0_all.deb \
  && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -q -y install esl-erlang elixir \
  && apt-get -q -y clean

ADD . /app

WORKDIR /app

RUN mix local.rebar --force
RUN mix deps.get

CMD mix run --no-halt