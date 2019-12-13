# README

muhme/quote - Rails web application, serving [zitat-service.de](https://www.zitat-service.de)

## Installation
You can use your own Rails development envrironment. Or you use prepared Docker development environment.
### Docker Development Environment
```
$ git clone https://github.com/muhme/quote
$ cd quote
$ docker-compose up
```
Then you have four containers running:
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
  * local directory with cloned GitHub repository is mounted into container
* quote_chrome - Selenium Standalone with Chrome and VNC server
  * vnc://localhost:8104 - to see browser working in test:system (using the password: secret)

## Testing

* rails test - to run automated unit tests: actual 142 tests, wich are covering 535 of 611 lines of code (88%)
* rails test:system - to run automated headless Chrome system tests: actual 34 tests, which are covering 404 of 627 lines of code (64%)

If your're using Docker, go into container first with:
```
$ docker exec -it quote_rails /bin/bash
```

## History

* 2006 developed with Rails 1.2
* 2009 migrated to Rails 2.0
* 2018 migrated to Rails 5.1.5 / 5.2.1 / 5.2.2
* 2019 migrated to Rails 5.2.3 / 5.2.4 / 6.0.1

## Contact

Don't hesitate to ask if you have any questions or comments.