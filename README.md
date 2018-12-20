# README

muhme/quote - Rails web application, serving [zitat-service.de](https://www.zitat-service.de)
* 2006 developed with Rails 1.2
* 2009 migrated to Rails 2.0
* 2018 migrated to Rails 5.1.5 / 5.2.1 / 5.2.2

## Installation
You can use your own Rails development envrironment. For starters there are two installation methods described following. First and recommended is to use Docker and second alternative is to use AWS Cloud9.
### 1st Method Docker
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
### 2nd Method AWS Cloud9 EC2
Short command list, used on AWS Cloud9 EC2 with Amazon Linux AMI 2017.09:
```
$ sudo yum install -y perl-CGI yum install perl-DBD-MySQL
$ git clone https://github.com/muhme/quote
$ cd quote
$ rvm use ruby-2.4.1@quote --ruby-version --create # ignore ln: failed to create sym link
$ sudo service mysqld restart
```
Set database root user passwd and creating quote database user:
```
$ /usr/libexec/mysql55/mysqladmin -u root password 'Your_mysql_root_password'
$ mysql -u root -pYour_mysql_root_password
mysql> CREATE USER 'quote'@'localhost' IDENTIFIED BY 'Your_quote_password';
mysql> GRANT ALL PRIVILEGES ON * . * TO 'quote'@'localhost';
mysql> quit
$ echo "QUOTE_DATABASE_PASSWORD='Your_quote_password' ; export QUOTE_DATABASE_PASSWORD" >> ~/.bash_profile
$ . ~/.bash_profile
$ sudo yum -y install mysql-devel
$ bundle install
$ rake db:create && rake db:migrate
$ rails server
```
Click on 'Preview' and choose 'Preview Running Application'. In the new small window click on the top right 'Pop out in new window' and you see the web application running. For Testing you have to set your host in file config/environments/test.rb.

To run the headless chrome system tests you have to do some more installation, see https://intoli.com/blog/installing-google-chrome-on-centos:
```
$ cd /tmp
$ wget http://chromedriver.storage.googleapis.com/2.35/chromedriver_linux64.zip
$ unzip chromedriver_linux64.zip
$ sudo mv chromedriver /usr/local/bin
$ curl https://intoli.com/install-google-chrome.sh | bash
```
## Testing

* rails test - to run automated tests (actual test coverage is 95% :)
* rails test:system - to run automated headless Chrome system tests (actual test coverage is 78% :|

## Contact

Don't hesitate to ask if you have any questions.
