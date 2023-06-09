# rails.Dockerfile - instructions to build Docker image for the Ruby on Rails based web application zitat-service.de
#
FROM ruby:3.0.6
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y net-tools vim node.js
RUN mkdir /quote
ADD . /quote
WORKDIR /quote
RUN gem install bundler:2.4.6 && bundle install
CMD /bin/bash -c 'rm -f tmp/pids/server.pid && rails s -p 3000 -b "0.0.0.0"'
