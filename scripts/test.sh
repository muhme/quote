#!/bin/bash
#
# scripts/test.sh - running mini tests and system tests
#
# source .bashrc to set $DEEPL_API_KEY
#
# MIT License, Copyright (c) 2007 - 2024 Heiko Lübbe
# Ruby on Rail web application https://www.zitat-service.de, see https://github.com/muhme/quote

echo ''
echo '*** Waiting for database to be ready'
docker exec -it quote_rails sh -c "scripts/wait_for_database.sh"

echo ''
echo '*** Running mini tests - rails test'
docker exec -it quote_rails sh -c ". ~/.bashrc && rails test"

echo ''
echo '*** Running system tests - rails test:system'
docker exec -it quote_rails sh -c ". ~/.bashrc && rails test:system"
