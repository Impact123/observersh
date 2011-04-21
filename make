#!/bin/bash
# Makefile for Server.sh Releases
clear

RELEASE="server-$(cat version.txt |awk {'print $2'}).tar.gz"
FILES="server.sh server.conf docs version.txt make"

chmod 755 server.sh server.conf 
tar cfvz $RELEASE $FILES
clear; echo "Release $(cat version.txt |awk {'print $2'}) gepackt."
