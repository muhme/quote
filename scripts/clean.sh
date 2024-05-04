#!/bin/bash
#
# scripts/clean.sh - delete all quote_* docker containers, but not quote_api_* nor quote_joomla_* etc.
#
# MIT License, Copyright (c) 2007 - 2024 Heiko Lübbe
# Ruby on Rail web application https://www.zitat-service.de, see https://github.com/muhme/quote

PATTERN="^quote_[a-z]*$"
echo ''
echo "*** Removing all docker containers ${PATTERN}"
docker ps -a --format '{{.Names}}' | grep "${PATTERN}" | xargs -r docker rm -f
