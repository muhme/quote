#!/bin/bash
#
# scripts/compose.sh - compose docker test & development environment
#
# 1. delete all docker containers
# 2. create docker containers, with optional script argument build, they are build with no cache
# 3. set DEEPL_API_KEY as taken from script running environment
# 4. doing Rails system test hack
#
# MIT License, Copyright (c) 2007 - 2024 Heiko Lübbe
# Ruby on Rail web application https://www.zitat-service.de, see https://github.com/muhme/quote

SCRIPTS_DIR=$(dirname $0)
"${SCRIPTS_DIR}/clean.sh"

if [ $# -eq 1 ] && [ "$1" = "build" ] ; then
  echo ''
  echo '*** Docker compose build --no-cache'
  docker compose build --no-cache
fi

echo ''
echo '*** Docker compose up'
docker compose up -d

echo ''
echo "*** Setting DEEPL_API_KEY=\"${DEEPL_API_KEY}\""
docker exec -it quote_rails sh -c "echo export DEEPL_API_KEY=${DEEPL_API_KEY} >> ~/.bashrc"
echo "DEEPL_API_KEY=${DEEPL_API_KEY}" > .env
