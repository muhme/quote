#!/bin/bash
#
# scripts/clean.sh - delete all quote_* docker containers, but not quote_api_* nor quote_joomla_* etc.
#
# MIT License, Copyright (c) 2007 - 2024 Heiko Lübbe
# Ruby on Rail web application https://www.zitat-service.de, see https://github.com/muhme/quote

PREFIX="quote_"
NETWORK_NAME="${PREFIX}default"

echo '*** Remove following Docker containers'
docker ps -a --format '{{.Names}}' | grep "^${PREFIX}" | xargs -r docker rm -f

echo '*** Remove following Docker network'
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  docker network rm "$NETWORK_NAME"
fi
