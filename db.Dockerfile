# db.Dockerfile - instructions to build Docker image with mariadb and load dump from zitat-service.de
# 
FROM mariadb
RUN mkdir -p /docker-entrypoint-initdb.d
WORKDIR /docker-entrypoint-initdb.d
RUN apt-get update && apt-get install -y git-core
WORKDIR /tmp
RUN git clone https://github.com/muhme/quote quote && mv quote/test/fixtures/files/quote_development.sql.gz /docker-entrypoint-initdb.d/quote_development.sql.gz && rm -rf quote
CMD ["mysqld"]
