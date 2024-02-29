# README

Ruby on Rails (RoR) web application running the website [zitat-service.de](https://www.zitat-service.de).

The database is used for JSON API [api.zitat-service.de](https://api.zitat-service.de) too.
The API itself is used by this RoR web application and also by the Joomla module
[github.com/muhme/quote_joomla](https://github.com/muhme/quote_joomla) and WordPress plugin
[github.com/muhme/quote_wordpress](https://github.com/muhme/quote_wordpress).

### Scripts

Some bash-scripts are prepared for a pleasant and also faster development, see folder [scripts](./scripts/) and
commented list of scripts there.

## Docker Containers
There is a Docker test and development environment prepared. You can create your own test and development instance
with the following commands:
```
$ git clone https://github.com/muhme/quote
$ cd quote
$ scripts/compose.sh
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
  * Database quote_development with database user quote_development/quote_development and LIVE database import from August 2023 and three additional users created with the three different user roles 
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
    * user/user_password/user@user.com
    * admin/admin_password/admin@admin.com
    * super_admin/super_admin/super_admin@admin.com
* quote_chrome – Selenium Standalone with Chrome and VNC server
  * two ports are available to see browser working in test:system (using the password: secret):
    * using a VNC viewer [vnc://localhost:8104](vnc://localhost:8104) or
    * using your browser (no VNC client is needed) http://localhost:8105/?autoconnect=1&resize=scale&password=secret
* quote_maildev – SMTP Server and Web Interface for viewing and testing emails during development
  * http://localhost:8106

## Machine Translation
<details>
  <summary>The application uses DeepL API Free for translation.</summary>
  
  You can register there and then use your own key in the rails application, in the tests and for translations
  with i18n-tasks command. The key has to be set in rails container's `.bashrc` by the compose script:
  
```
host $ DEEPL_API_KEY="sample11-key1-ab12-1234-qbc123456789:fx" scripts/compose.sh
```
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

  While the system tests are running, you can access the test environment in parallel via http://localhost:8112.
  Or you can start the Rails server for the test environment manually inside the docker container:
  ```
  quote_rails $ export PORT=3100 && rails server --environment test -P /tmp/test.pid
  ```

:point_right: If you are using Rails 7.1.3.2 there is a hack needed to run the system tests. `scripts/compose.sh`
is doing it by extending line #19 in file
`/usr/local/bundle/gems/actionpack-7.1.3.2/lib/action_dispatch/system_testing/driver.rb`,
see [rails/issues/50827](https://github.com/rails/rails/issues/50827):
```
< @browser.preload
> @browser.preload unless @options[:browser] == :remote
```
</details>

## History

* 2024 upgraded to Rails 7.1.3
* 2023 updated Rails 7.0.5 ... 7.0.8, Ruby 3.1
* 2023 everything translated from German 🇩🇪 into English 🇺🇸, español 🇪🇸, 日本語 🇯🇵 and українська 🇺🇦
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
