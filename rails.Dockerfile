# rails.Dockerfile - instructions to build Docker image for the Ruby on Rails based web application zitat-service.de
#
# Feb-2-2024 CentOS 9 Stream is only supporting Ruby 3.1, see dnf module list ruby
FROM ruby:3.1
# nc for scripts/wait_for_database.sh
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y net-tools vim node.js iputils-ping netcat-traditional
RUN mkdir /quote
ADD . /quote
WORKDIR /quote
RUN gem install bundler:2.4.6 && bundle install
# source .env with DEEPL_API_KEY here to prevent not having .env from git clone in docker compose
CMD /bin/bash -c 'if [ -f "/quote/.env" ]; then set -o allexport; source /quote/.env; set +o allexport; fi && rm -f tmp/pids/server.pid && rails s -p 3000 -b "0.0.0.0"'
