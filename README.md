# README

muhme/quote - Rails web application, serving [zitat-service.de]
* 2006 developed with Rails 1.2
* 2009 migrated to Rails 2.0
* 2018 ongoing migration to Rails 5.1.5

The migration to Rails 5.1.5 is ongoing, some parts of the web applications are usable now.

## Installation
Short command list, used on AWS Cloud9:
```
$ git clone https://github.com/muhme/quote
$ cd quote
$ sudo yum install -y mysql-devel wget
$ rvm use ruby-2.4.1@quote --ruby-version -create
$ wget https://dev.mysql.com/get/mysql57-community-release-el6-11.noarch.rpm
$ sudo yum localinstall -y mysql57-community-release-el6-11.noarch.rpm
$ sudo yum remove -y mysql55 mysql55-common mysql55-libs mysql55-server
$ sudo yum install -y mysql-community-server
$ sudo service mysqld restart
$ grep "temporary password" /var/log/mysqld.log
```
Set database root user passwd:
````
$ mysql -u root -p 'see_password_from_grep' with ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password;"

$ echo "QUOTE_DATABASE_PASSWORD='your_password' ; export QUOTE_DATABASE_PASSWORD" >> ~/.bash_profile
$ . ~/.bash_profile
$ rake db:create && rake db:migrate
$ rails server

## Testing

* rails test - to run automated tests
* rails test_system - to run automated headless Chrome system tests

### Headless Chrome system tests
To run the headless chrome system tests you have to do some more installation, see [https://intoli.com/blog/installing-google-chrome-on-centos]:
```
$ curl https://intoli.com/install-google-chrome.sh | bash
```

## Contact

Don't hesitate to ask if you have any questions.
