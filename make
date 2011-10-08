#!/bin/bash
# Makefile for Server.sh Releases
clear

FILES="server.sh server.conf version.txt make docs/CHANGELOG docs/LICENSE docs/README"

for i in $FILES; do
  if ! [ -f "$i" ]; then
    echo "Error: Missing '$i'"
	LOCK="1"
  fi
done

[ $LOCK == "1" ] && exit 1

RELEASE="server-$(cat version.txt |grep 'Version:' |awk {'print $2'}).tar.gz"

chmod 600 server.conf version.txt docs/CHANGELOG docs/LICENSE docs/README
chmod 700 server.sh make
tar cfz $RELEASE $FILES
clear; echo "Release $RELEASE gepackt."
