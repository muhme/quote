# README

muhme/quote - Rails web application, serving [zitat-service.de](https://www.zitat-service.de)

## Docker Containers
There is a Docker test and development environment prepared. You can create your own test and development instance with the following commands:
```
$ git clone https://github.com/muhme/quote
$ cd quote
$ docker compose up -d
```
Then you should have five containers running:
```
$ docker ps
IMAGE                              COMMAND                  PORTS                                            NAMES
mariadb                            "docker-entrypoint.s…"   0.0.0.0:8100->3306/tcp                           quote_mariadb
phpmyadmin/phpmyadmin              "/docker-entrypoint.…"   0.0.0.0:8101->80/tcp                             quote_mysqladmin
quote_rails                        "/bin/sh -c '/bin/ba…"   0.0.0.0:8102->3000/tcp, 0.0.0.0:8103->3100/tcp   quote_rails
selenium/standalone-chrome-debug   "/opt/bin/entry_poin…"   4444/tcp, 0.0.0.0:8104->5900/tcp                 quote_chrome
djfarrelly/maildev                 "bin/maildev --web 8…"   25/tcp, 0.0.0.0:8105->80/tcp                     quote_maildev
```
* quote_mariadb - MariaDB database server
  * database admin is root/root
  * database quote_development with user quote_development/quote_development created and June 2018 database export loaded
  * database quote_test with user quote_test/quote_test created
* quote_mysqladmin - phpMyAdmin (user root/root)
  * http://localhost:8101
* quote_rails - Rails web application zitat-service
  * http://localhost:8102
  * getting Shell with: "docker exec -it quote_rails bash"
  * running function tests with "docker exec -it quote_rails rails t"
  * running system tests using Chrome browser on Selenium container with "docker exec -ti quote_rails rails test:system"
  * local directory /quote with cloned GitHub repository is mounted into container
* quote_chrome - Selenium Standalone with Chrome and VNC server
  * [vnc://localhost:8104](vnc://localhost:8104) - to see browser working in test:system (using the password: secret)
* quote_maildev - SMTP Server and Web Interface for viewing and testing emails during development
  * http://localhost:8105 

## Testing

Test coverage is greater than 90%, check it by your own:
* rails test - to run automated unit tests
* rails test:system - to run automated headless Chrome system tests

**Note**
> If your're using Docker, go into container first with:
```
$ docker exec -it quote_rails /bin/bash
```

## History

* 2022 updated to Ruby 3.1 and Rails 7.0.1 ... 7.0.4
* 2021 updated to Rails 6.1.3 ... 6.1.4
* 2020 updated to Rails 6.0.2 ... 6.1.0
* 2019 updated to Rails 5.2.3 / 5.2.4, upgraded to 6.0.1
* 2018 migrated to Rails 5.1.5, updated to Rails 5.2.1 / 5.2.2
* 2009 upgraded to Rails 2.0
* 2006 developed with Rails 1.2

## Contact

Don't hesitate to ask if you have any questions or comments.
