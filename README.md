# README

muhme/quote - Ruby on Rails web application, serving website [zitat-service.de](https://www.zitat-service.de)

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
IMAGE                        PORTS                                                      NAMES
quote-rails                  0.0.0.0:8102->3000/tcp                                     quote_rails
phpmyadmin/phpmyadmin        0.0.0.0:8101->80/tcp                                       quote_mysqladmin
mariadb                      3306/tcp                                                   quote_mariadb
selenium/standalone-chrome   4444/tcp, 0.0.0.0:8104->5900/tcp, 0.0.0.0:8105->7900/tcp   quote_chrome
maildev/maildev              1025/tcp, 0.0.0.0:8106->1080/tcp                           quote_maildev
```
* quote_mariadb – MariaDB database server
  * database admin user is root/root
  * Database quote_development with database user quote_development/quote_development and LIVE database import from June 2023 and three additional users created with the three different user roles 
  * database quote_test with database user quote_test/quote_test created
* quote_mysqladmin – phpMyAdmin (user root/root)
  * http://localhost:8101
* quote_rails – Rails web application zitat-service
  * http://localhost:8102
  * getting Shell with: "docker exec -it quote_rails bash"
  * running function tests with "docker exec -it quote_rails rails t"
  * running system tests using Chrome browser on Selenium container with "docker exec -ti quote_rails rails test:system"
  * local directory /quote with cloned GitHub repository is mounted into container
  * users available are:
    * user/user_password
    * admin/admin_password
    * super_admin/super_admin
* quote_chrome – Selenium Standalone with Chrome and VNC server
  * two ports are available to see browser working in test:system (using the password: secret):
    * using a VNC viewer [vnc://localhost:8104](vnc://localhost:8104) or
    * using your browser (no VNC client is needed) http://localhost:8105/?autoconnect=1&resize=scale&password=secret
* quote_maildev – SMTP Server and Web Interface for viewing and testing emails during development
  * http://localhost:8106

## Machine Translation
<details>
  <summary>The application uses DeepL API Free for translation.</summary>
  
  You can register there and then store your own API key in the .env file.
```
DEEPL_API_KEY="sample11-key1-ab12-1234-qbc123456789:fx"
```
You can also set this DEEPL_API_KEY in the environment for translations with i18n-tasks.
</details>

## Testing

<details>
  <summary>Mini tests and system tests are available for application validation.</summary>

  Test coverage is greater than 90%, check it by your own:
  * rails test - to run automated minitests
  * rails test:system - to run automated Selenium system tests with Chrome browser

  **Note**
  > If your're using Docker, go into container first with:
  ```
  $ docker exec -it quote_rails /bin/bash
  ```

  After running the tests you can find simplecov report in the directory coverage, e.g.:
  ![simplecov.png](/app/assets/images/simplecov.png)

  While the system tests are running, you can access the test environment in parallel via http://localhost:8112. Or you can start the Rails server for the test environment manually inside the docker container:
  ```
  quote_rails $ export PORT=3100 && rails server --environment test -P /tmp/test.pid
  ```
</details>


## History

* 2023 updated Rails 7.0.5
* 2023 translated web application interface in English 🇺🇸, español 🇪🇸, 日本語 🇯🇵 und українська 🇺🇦
* 2023 using Hotwire Turbo (see [Autocomplete mit Rails & Turbo](https://www.consulting.heikol.de/en/blog/autocomplete-ruby-on-rails-turbo/))
* 2022 updated to Ruby 3.0 and Rails 7.0.1 ... 7.0.4
* 2021 updated to Rails 6.1.3 ... 6.1.4
* 2020 updated to Rails 6.0.2 ... 6.1.0
* 2019 updated to Rails 5.2.3 / 5.2.4, upgraded to 6.0.1
* 2018 migrated to Rails 5.1.5, updated to Rails 5.2.1 / 5.2.2
* 2009 upgraded to Rails 2.0
* 2006 developed with Rails 1.2

## Contact

Don't hesitate to ask if you have any questions or comments.
