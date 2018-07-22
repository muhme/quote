# rails.Dockerfile - instructions to build Docker image with Ruby on Rails based web application zitat-service.de
#
FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /quote
WORKDIR /quote
RUN git clone https://github.com/muhme/quote /quote
# already set hostname 'db' for development
# RUN sed -i 's/host: localhost/host: db/' config/database.yml
RUN bundle install
CMD /bin/bash -c 'rails s -p 3000 -b "0.0.0.0"'
