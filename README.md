# README

muhme/quote - Rails web application, serving [zitat-service.de](https://www.zitat-service.de)
* 2006 developed with Rails 1.2
* 2009 migrated to Rails 2.0
* 2018 ongoing migration to Rails 5.1.5

The migration to Rails 5.1.5 is ongoing, some parts of the web applications are usable now.

## Installation
Short command list, used on AWS Cloud9 EC2 with Amazon Linux AMI 2017.09:
```
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
Click on 'Preview' and choose 'Preview Running Application'. In the new small window click on the top right 'Pop out in new window' and you see the web application running.
## Testing

* rails test - to run automated tests
* rails test:system - to run automated headless Chrome system tests

### Headless Chrome system tests
To run the headless chrome system tests you have to do some more installation, see https://intoli.com/blog/installing-google-chrome-on-centos:
```
$ cd /tmp
$ wget http://chromedriver.storage.googleapis.com/2.35/chromedriver_linux64.zip
$ unzip chromedriver_linux64.zip
$ sudo mv chromedriver /usr/local/bin
$ curl https://intoli.com/install-google-chrome.sh | bash
```

## Contact

Don't hesitate to ask if you have any questions.
