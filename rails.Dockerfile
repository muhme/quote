# rails.Dockerfile - instructions to build Docker image for the Ruby on Rails based web application zitat-service.de
#
FROM ruby:3.2
RUN apt-get update -qq && apt-get upgrade -y
RUN mkdir /quote
ADD . /quote
WORKDIR /quote
RUN bundle install
CMD /bin/bash -c 'rm -f tmp/pids/server.pid && rails s -p 3000 -b "0.0.0.0"'
