#!/bin/bash
# Makefile for Server.sh Releases
clear

RELEASE="server-$(cat version.txt |grep 'Version:' |awk {'print $2'}).tar.gz"
FILES="server.sh server.conf docs version.txt make"

chmod 700 server.sh
tar cfvz $RELEASE $FILES
clear; echo "Release $RELEASE gepackt."
