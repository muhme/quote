#!/bin/bash
#
# scripts/wait_for_database.sh – wait in the rails container for database to be ready in mariadb container
#
# MIT License, Copyright (c) 2007 - 2024 Heiko Lübbe
# Ruby on Rail web application https://www.zitat-service.de, see https://github.com/muhme/quote

DB_HOST="db"   # MariaDB container hostname
DB_PORT="3306" # MariaDB port
counter=60     # timeout counter

while [[ $counter -gt 0 ]]; do
    nc -z $DB_HOST $DB_PORT > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        break
    else
        echo "waiting for database – count down $counter"
        ((counter--))
        sleep 1
    fi
done

if [[ $counter -eq 0 ]]; then
    echo "Failed to connect to database"
    exit 1
fi
