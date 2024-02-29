# Scripts for a more pleasant and also faster development

These scripts support the development and testing of the RoR web application running [zitat-service.de](https://www.zitat-service.de). (see [../README.md](../README.md)).

The scripts are used on the Mac command line and inside Docker container, but should also work on Linux and the Windows subsystem for Linux.

| Script | Description | Additional Info |
| --- | --- | --- |
| [scripts/compose.sh](compose.sh) | Compose docker test & development environment. | - 1st delete all docker containers<br />- 2nd create docker containers (with optional script argument `build`, they are build with no cache)<br />- 3rd set DEEPL_API_KEY (as taken from script running environment)<br />- 4th doing Rails system test hack<br />  |
| [scripts/test.sh](test.sh) | Run all the tests in the rails container. | - running rails test and rails test:system |
| [scripts/wait_for_database.sh](wait_for_database.sh) | Wait in the rails container for database to be ready in mariadb container. | - count down 60 seconds |
| [scripts/clean.sh](clean.sh) | Removes all quote_* Docker containers. | - but not quote_api_* nor quote_joomla_* etc. |

And now you are ready to double the speed :smiley: Create the five Docker containers and running all the test with just one command line:
```
host$ scripts/compose.sh && scripts/test.sh
```
