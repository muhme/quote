# rails.Dockerfile - instructions to build Docker image with Ruby on Rails based web application zitat-service.de
#
FROM ruby:2.6
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /quote
ADD . /quote
WORKDIR /quote
RUN bundle install
CMD /bin/bash -c 'rails s -p 3000 -b "0.0.0.0"'
