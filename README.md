# README

Ruby on Rails (RoR) web application running the website [zitat-service.de](https://www.zitat-service.de).

The database is used for JSON API [api.zitat-service.de](https://api.zitat-service.de) too.
The API itself is used by this RoR web application and also by the Joomla module
[github.com/muhme/quote_joomla](https://github.com/muhme/quote_joomla) and WordPress plugin
[github.com/muhme/quote_wordpress](https://github.com/muhme/quote_wordpress).

## Scripts

Some bash-scripts are prepared for a pleasant and also faster development, see folder [scripts](./scripts/) and
commented list of scripts there.

### Prerequisites

[Git](https://git-scm.com/) and [Docker](https://www.docker.com/) in a scripting environment are required. Tested with macOS 14 Sonoma, Ubuntu 22 Jammy Jellyfish and Microsoft Windows 11 WSL 2.

## Docker Containers
There is a Docker test and development environment prepared.
You can create your own local test and development instance with the following commands:
```
git clone https://github.com/muhme/quote
cd quote
scripts/compose.sh
```
Then five containers are running:
```
NAMES              IMAGE                        PORTS
quote_rails        quote-rails                  0.0.0.0:8102->3000/tcp
quote_mysqladmin   phpmyadmin/phpmyadmin        0.0.0.0:8101->80/tcp
quote_mariadb      mariadb                      3306/tcp
quote_chrome       selenium/standalone-chrome   4444/tcp, 0.0.0.0:8104->5900/tcp, 0.0.0.0:8105->7900/tcp
quote_maildev      maildev/maildev              1025/tcp, 0.0.0.0:8106->1080/tcp
```
* quote_mariadb – MariaDB database server
  * database admin user is root/root
  * Database quote_development with database user quote_development/quote_development and cleaned LIVE database import from August 2023 and three additional users created with the three different user roles 
  * database quote_test with database user quote_test/quote_test created
* quote_mysqladmin – phpMyAdmin (user root/root)
  * http://localhost:8101
* quote_rails – Rails web application zitat-service
  * http://localhost:8102
  * local directory `/quote` with cloned GitHub repository is mounted into container
  * users available are:
    * user / user_password / user@user.com
    * admin / admin_password / admin@admin.com
    * super_admin / super_admin / super_admin@admin.com
* quote_chrome – Selenium Standalone with Chrome and VNC server
  * two ports are available to see browser working in system test (using the password: secret):
    * using a VNC viewer: [vnc://localhost:8104](vnc://localhost:8104) or
    * using your browser (no VNC client is needed):<br />
      http://localhost:8105/?autoconnect=1&resize=scale&password=secret
* quote_maildev – SMTP Server and Web Interface for viewing and testing mails during development
  * http://localhost:8106

## Machine Translation
<details>
  <summary>The application uses DeepL API Free for translation.</summary>
  
  You can register there for free and then use your own key in the rails application, in the tests and for translations
  with i18n-tasks command. The easiest way is to start with `DEEPL_API_KEY` at the beginning:

  ```
  DEEPL_API_KEY="sample11-key1-ab12-1234-qbc123456789:fx" scripts/compose.sh
  ```

  Or set the key manually in `.env` file and  in the `.bashrc` of the `quote_rails` container.

You can then use machine translation on the development server. The tests that use machine translation will run.
And you can use `i18n-tasks` within the Rails container to check if the keys are ok, normalize the order or
translate missing keys:
```
docker exec -it quote_rails i18n-tasks health
docker exec -it quote_rails i18n-tasks normalize
docker exec -it quote_rails bash -c ". ~/.bashrc && i18n-tasks translate-missing --backend=deepl"
```
</details>

## Testing

<details>
  <summary>Mini tests and system tests are available for application validation.</summary>

  You can run all mini tests and system tests:
  ```
  scripts/test.sh
  ```

  Mini tests are sometimes integration tests, when the interaction with external services
  such as Deepl or Gravatar is also tested.

  After running the tests you can find simplecov report in the directory coverage, e.g.:
  ![simplecov.png](/app/assets/images/simplecov.png)

  While the system tests are running, you can access the test environment web application in parallel via http://localhost:8112.
  Or you can start the Rails server for the test environment manually inside the docker container to inspect the web application working with test test environment data:
  ```
  docker exec -it quote_rails bash -c "export PORT=3100 && rails server --environment test -P /tmp/test.pid"
  ```

:point_right: If you are using Rails 7.1.3.3 there is a hack needed to run the system tests. `scripts/compose.sh`
is doing it by extending line #19 in file
`/usr/local/bundle/gems/actionpack-7.1.3.2/lib/action_dispatch/system_testing/driver.rb`,
see [rails/issues/50827](https://github.com/rails/rails/issues/50827):
```
< @browser.preload
> @browser.preload unless @options[:browser] == :remote
```
</details>

## JavaScript

For JavaScript files and debugging see folder [app/javascript](./app/javascript/).

## New Server Version
<details>
  <summary>Todo list before create a new server image:</summary>

* bundle update
* check ES Module Shims for new version
  * https://www.npmjs.com/package/es-module-shims
  * download into public/javascripts and removing source map reference in the end
* git commit -a
* scripts/compose.sh && scripts/test.sh
* git push
* drop folder `quote` into trash and create fresh new and test:
  * git clone https://github.com/muhme/quote
  * cd quote && scripts/compose.sh build && scripts/test.sh

</details>

## History

* 2024 upgraded to Rails 7.1.3, added avatar images
* 2023 updated Rails 7.0.5 ... 7.0.8, Ruby 3.1
* 2023 everything translated from German into English, español, 日本語 and українська
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
