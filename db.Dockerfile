# db.Dockerfile - instructions to build Docker image with mariadb and load dump from zitat-service.de
# 
FROM mariadb
RUN mkdir -p /docker-entrypoint-initdb.d /quote
ADD . /quote
RUN cp /quote/test/fixtures/files/quote_development.sql.gz /docker-entrypoint-initdb.d/quote_development.sql.gz
RUN echo "create database quote_test; grant all on quote_test.* to 'quote_test'@'%' identified by 'quote_test';" > /docker-entrypoint-initdb.d/quote_test.sql
CMD ["mysqld"]
