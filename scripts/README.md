# Scripts for a more pleasant and also faster development

These scripts support the development and testing of the RoR web application running [zitat-service.de](https://www.zitat-service.de). (see [../README.md](../README.md)).

The scripts are used on the Mac command line and inside Docker container, but should also work on Linux and the Windows subsystem for Linux.

| Script | Description | Additional Info |
| --- | --- | --- |
| [scripts/compose.sh](compose.sh) | Compose docker test & development environment. | - 1st delete all `quote_*` docker containers<br />- 2nd create docker containers (with optional script argument `build`, they are build with no cache)<br />- 3rd set `DEEPL_API_KEY` (as taken from script running environment)  |
| [scripts/test.sh](test.sh) | Run all the tests in the rails container. | - running `rails test` and `rails test:system` |
| [scripts/wait_for_database.sh](wait_for_database.sh) | Wait in the rails container for database to be ready in mariadb container. | - count down 60 seconds |
| [scripts/clean.sh](clean.sh) | Removes all quote_* Docker containers. | - but not quote_api_* nor quote_joomla_* etc. |

And now you are ready to double the speed :smiley: Create the five Docker containers and running all the test with just one command line:
```
host$ DEEPL_API_KEY="sample11-key1-ab12-1234-qbc123456789:fx" scripts/compose.sh && scripts/test.sh

*** Removing all docker containers ^quote_[a-z]*$

*** Docker compose up
 ✔ Container quote_mariadb     
 ✔ Container quote_chrome      
 ✔ Container quote_maildev     
 ✔ Container quote_rails       
 ✔ Container quote_mysqladmin  

*** Setting DEEPL_API_KEY="sample11-key1-ab12-1234-qbc123456789:fx"

*** Rails system test hack /usr/local/bundle/gems/actionpack-7.1.3.2/lib/action_dispatch/system_testing/driver.rb

*** Waiting for database to be ready
waiting for database – count down 60
waiting for database – count down 59
waiting for database – count down 58

*** Running mini tests - rails test
Run options: --seed 1132

# Running:
...........................................................................................................................................................................................................................................................

Finished in 103.935895s, 2.4150 runs/s, 8.1011 assertions/s.
251 runs, 842 assertions, 0 failures, 0 errors, 0 skips

*** Running system tests - rails test:system
Run options: --seed 55691

# Running:

Capybara starting Puma...
* Version 6.4.2, codename: The Eagle of Durango
* Min threads: 0, max threads: 4
* Listening on http://0.0.0.0:3100
............................................................................................................................................................

Finished in 1056.691558s, 0.1486 runs/s, 2.0176 assertions/s.
157 runs, 2132 assertions, 0 failures, 0 errors, 0 skips
```
