#!/bin/bash

# Script to build standalone release versions of ws-client.q and ws-server.q

RELEASE=${1}

cat ws-handler/ws-handler.q ws-client/ws.q > ws-client_${RELEASE}.q
cat ws-handler/ws-handler.q ws-server/wsu.q > ws-server_${RELEASE}.q
sed "s/.utl.require\"ws-server\"/\\\\l ws-server_${RELEASE}.q/g" wschaintick.q > wschaintick_${RELEASE}.q