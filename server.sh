#!/bin/bash
# 
#
# Ueber Das Script
# ---------------------------------------------------------------------------------------------
# Name:    - Gameserververwaltungsscript fuer Orangebox-Games 
# Version: - 0.2.5-Beta2
# Author:  - Impact, http://gugy.eu
# Lizens:  - GPLv3
# E-Mail:  - support@gugy.eu
# Web:     - http://gugyclan.eu
# Datum:   - 12.08.2011
#
#
#
#    Copyright (C) © 2010-2011 by GuGy.eu
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# 
#
# ---------------------------------------------------------------------------------------------

VERSION="Version: 0.2.5-Beta2"

# FARBEN
GELB="\033[1;33m"
ROT="\033[0;31m"
FARBLOS="\033[0m"


# STARTUP_LOCK AUF 0 SETZEN
STARTUP_LOCK="0"

# SCRIPTAUFRUF VON UEBERALL
cd $(dirname $0)


  clear
# CONFIGCHECK
if [ -r "server.conf" ]; then
  source server.conf
else
  echo -e $ROT"Error:$FARBLOS Configdatei fehlt oder Pfad ist falsch."
  exit
fi

# ADMINCHECK
if [ "`whoami`" == "root" ]; then
  echo -e $ROT"Error:$FARBLOS Verantwortungsvolle Admins starten Gameserver nicht mit dem root User."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  echo ""
fi

 # QSTATCHECK
if [[ ! `which $QUAKESTAT` ]]; then
  echo -e $ROT"Error:$FARBLOS Paket $QUAKESTAT nicht gefunden,"
  echo "sie sollten es installieren oder die Variable in der Kopfzeile anpassen."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  echo ""
fi

# DIRCHECK
if [ "$DIR" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde kein Dir angegeben."
  echo    "    [- Es wurde folgendes Verzeichnis ausgelesen"
  echo -e $GELB"    [- $(pwd)"$FARBLOS
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  echo ""
fi
  
# DIRCHECK2
if [ ! -d "$DIR" ]; then
  echo -e $ROT"Error:$FARBLOS Das Verzeichnis '$DIR' scheint nicht zu existieren"
  echo    "    [- Es wurde folgendes Verzeichnis ausgelesen"
  echo -e $GELB"    [- $(pwd)"$FARBLOS
  
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  
  # DIR DOESNT EXIST SETZEN
  DIR_DOESNT_EXIST="1"
  echo ""
fi

# SCRENNNAMECHECK
if [ "$SCREENNAME" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde kein Screenname angegeben."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  echo ""
fi

# IPCHECK
DEVICE="eth0"
# GERMAN / ENGLISH SYSTEM CHECK
if [[ "$(/sbin/ifconfig $DEVICE |grep "inet Adresse:"| awk '{ print $2}' |awk -F: '{print $2}')" ]]; then
  INET_ADRESS="$(/sbin/ifconfig $DEVICE |grep "inet Adresse:"| awk '{ print $2}' |awk -F: '{print $2}')"
else
  INET_ADRESS="$(/sbin/ifconfig $DEVICE |grep "inet addr:"| awk '{ print $2}' |awk -F: '{print $2}')"
fi

if [ "$IP" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde keine IP angegeben."
  echo -e "    [- Es wurde folgende ipv4-Adresse ausgelesen"
  echo -e $GELB"    [- $INET_ADRESS"$FARBLOS
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  echo ""
fi

if [ "$PORT" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde kein Port angegeben."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
  echo ""
fi

# DIRWRAPPER
if [ ! "$DIR_DOESNT_EXIST" == "1" ]; then
    
    # DIRCHECK 3 - IST UNSER VERZEICHNIS DAS RICHTIGE
    if [ ! "$DIR" == "$(pwd)" ]; then
      echo -e $ROT"Error:$FARBLOS Das Verzeichnis '$DIR' scheint nicht das richtige Verzeichnis zu sein."
	  echo    "    [- Der Pfad in welchem sich das Script befindet lautet:"
      echo -e $GELB"    [- $(pwd)"$FARBLOS
      # STARTUP_LOCK SETZEN
      STARTUP_LOCK="$[$STARTUP_LOCK+1]"
	  echo ""
    fi

    # EXTENSIONDIRCHECK
    if [ ! -d "$DIR/extensions" ]; then 
      mkdir $DIR/extensions
    fi

    # TMPDIRCHECK
    if [ ! -d "$DIR/tmp" ]; then 
      mkdir $DIR/tmp
    fi
	
fi

 # STARTUP_LOCK CHECKEN
 if [ ! "$STARTUP_LOCK" == "0" ]; then
   echo ""
   echo -e $GELB"Es wurden mindestens '$STARTUP_LOCK' Probleme gefunden, Start verhindert."$FARBLOS
   exit
fi


# --- PARAMETERZUSAETZE --- #
while getopts "cfCF" StartParams; do
case "$StartParams" in

c|C)
  GELB=""
  ROT=""
  FARBLOS=""
;;

f|F)
  FORCE_ACTIONS="1"
;;

\?)
  echo "Error: Falscher Startparameter."
  exit 1
;;

esac
done
shift $(($OPTIND -1))
# --- PARAMETERZUSAETZE --- #
 
 
# START - BEGINN DES SCRIPTES
# ---------------------------------------------------------------------------------------------
function SERVER_SH_START {
# GAMECHECK
if [ ! -d "$DIR/$SRCDSDIR" ]; then
  echo -e $ROT"Error:$FARBLOS Srcdsdir '$SRCDSDIR' existiert nicht."
  exit
fi

# LOGDIRCHECK
if [ ! -d "$DIR/$SRCDSDIR/$LOGDIR" ]; then
  mkdir $DIR/$SRCDSDIR/$LOGDIR
fi

# START WAEHREND UPDATE VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  echo -e $ROT"Error:$FARBLOS Update $SCREENNAME-update laeuft noch, Server kann nicht gestartet werden."
  exit
fi

# START WAEHREND BACKUP VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-backup` ]]; then
  echo -e $ROT"Error:$FARBLOS Backup $SCREENNAME-backup laeuft noch, Server kann nicht gestartet werden."
  exit
fi

# DOPPELSTART VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  echo -e $ROT"Error:$FARBLOS Server $SCREENNAME-running laeuft noch, Server kann nicht gestartet werden."
  exit
fi

# SCREENLOGCHECK
if [ -f "$DIR/$SRCDSDIR/screenlog.0" ]; then 
  cd $DIR/$SRCDSDIR
  mv screenlog.0 $LOGDIR
  cd $DIR/$SRCDSDIR/$LOGDIR
  mv screenlog.0 "screenlog.0_`$DATE`"
fi

# LOGTIMECHECK
if [[ `find $DIR/$SRCDSDIR/$LOGDIR/ -type f -name "screenlog.0_*"` ]]; then 
  find $DIR/$SRCDSDIR/$LOGDIR/ -type f -name "screenlog.0_*" -mtime +$LOGTIME $LOGEXEC
fi

# PORTCHECK
if [[ `netstat -aunx |grep $PORT` ]]; then
  echo -e $ROT"Error:$FARBLOS Port $PORT ist schon belegt"
  exit
fi

# BINARYCHECK
if [ ! -f "$DIR/$SRCDSDIR/$BINARY" ]; then
  echo -e $GELB"Binary '$BINARY' existiert nicht."$FARBLOS
  exit
fi

cd $DIR/$SRCDSDIR
screen -$SCREENOPTIONS $SCREENNAME-running ./$BINARY -game $GAMEMOD -port $PORT +ip $IP +map $MAP +maxplayers $MAXPLAYERS $EXTRA

# SERVER STARTED CHECK - IST DER SERVER WIRKLICH GESTARTET?  
# SLEEP TO LET SOME TIME FOR SCREEN TO CLOSE THE SESSION IF SOMETHING FAILS
sleep 0.05
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  echo -e $GELB"Server $SCREENNAME wurde gestartet."$FARBLOS
else
  echo -e $GELB"Server $SCREENNAME wurde nicht gestartet, anscheinend gab es einen Fehler."$FARBLOS
fi


# --- EXTENSIONS --- #

# FUER JEDE EXTENSION IM ORDNER
for EXTENSION in $(find $DIR/extensions/ -type f -name "*_extension.sh" |awk -F "extensions/" {'print $2'}); do

# FALLS AUSFUEHRBAR
  if [ ! -x "$DIR/extensions/$EXTENSION" ]; then
    chmod 700 $DIR/extensions/$EXTENSION
	$DIR/extensions/$EXTENSION start
  else
    $DIR/extensions/$EXTENSION start
  fi
done
# --- EXTENSIONS --- #
}
# ---------------------------------------------------------------------------------------------



# STOP
# ---------------------------------------------------------------------------------------------
function SERVER_SH_STOP {

# FALLS FORCE
if [ "$FORCE_ACTIONS" == "1" ]; then
  CHECK_BEFORE_SHUTDOWN="0"
fi

# WENN CHECK AKTIVIERT
if [ "$CHECK_BEFORE_SHUTDOWN" == "1" ] || [ "$CHECK_BEFORE_SHUTDOWN" == "on" ]; then

  # FALLS SERVER ANPINGBAR
  if [ ! "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" == "DOWN" ]; then

  # FALLS UNTER 10 SPIELER
    if [[ ! "$($QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $2}' |awk -F '/' '{print $2}')" == "$MAXPLAYERS" ]]; then
      PLAYERS_ONLINE="`$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2,$3}' |tr -d ' ' |awk -F '/' {'print $1'}`"
    else
      PLAYERS_ONLINE="`$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2}' |awk -F '/' {'print $1'}`"
    fi
	
    # FALLS SPIELERZAHL UEBER NULL UND KEIN NO RESPONSE
    if [ ! "$PLAYERS_ONLINE" == "0" ] && [ ! "$PLAYERS_ONLINE" == "noresponse" ]; then
      clear; echo -e $GELB"Es sind '$PLAYERS_ONLINE' Spieler auf dem Server, Server wird nicht gestoppt."$FARBLOS
	  exit
    fi
	
  fi
  
fi


# CHECK OB SERVER LAEUFT
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  screen -dr $SCREENNAME-running -X quit 
  echo -e $GELB"Server $SCREENNAME wurde gestoppt."$FARBLOS
else
  echo -e $ROT"Error:$FARBLOS Server $SCREENNAME ist bereits gestoppt."
fi

# --- EXTENSIONS --- #

# FUER JEDE EXTENSION IM ORDNER
for EXTENSION in $(find $DIR/extensions/ -type f -name "*_extension.sh" |awk -F "extensions/" {'print $2'}); do

# FALLS AUSFUEHRBAR
  if [ ! -x "$DIR/extensions/$EXTENSION" ]; then
    chmod 700 $DIR/extensions/$EXTENSION
	$DIR/extensions/$EXTENSION stop
  else
    $DIR/extensions/$EXTENSION stop
  fi
done
# --- EXTENSIONS --- #

}
# ---------------------------------------------------------------------------------------------



# RESTART
# ---------------------------------------------------------------------------------------------
function SERVER_SH_RESTART {
SERVER_SH_STOP
sleep 1
SERVER_SH_START
}
# ---------------------------------------------------------------------------------------------



# UPDATE
# ---------------------------------------------------------------------------------------------
function SERVER_SH_UPDATE {

# FALLS FORCE
if [ "$FORCE_ACTIONS" == "1" ]; then
  CHECK_BEFORE_SHUTDOWN="0"
fi

# WENN CHECK AKTIVIERT
if [ "$CHECK_BEFORE_SHUTDOWN" == "1" ] || [ "$CHECK_BEFORE_SHUTDOWN" == "on" ]; then

  # FALLS SERVER ANPINGBAR
  if [ ! "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" == "DOWN" ]; then

  # FALLS UNTER 10 SPIELER
    if [[ ! "$($QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $2}' |awk -F '/' '{print $2}')" == "$MAXPLAYERS" ]]; then
      PLAYERS_ONLINE="`$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2,$3}' |tr -d ' ' |awk -F '/' {'print $1'}`"
    else
      PLAYERS_ONLINE="`$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2}' |awk -F '/' {'print $1'}`"
    fi
	
    # FALLS SPIELERZAHL UEBER NULL UND KEIN NO RESPONSE
    if [ ! "$PLAYERS_ONLINE" == "0" ] && [ ! "$PLAYERS_ONLINE" == "noresponse" ]; then
      clear; echo -e $GELB"Es sind '$PLAYERS_ONLINE' Spieler auf dem Server, Update wird nicht fortgesetzt."$FARBLOS
	  exit
	fi
	
  fi
  
fi


# FALLS SERVER NOCH LAEUFT
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  UPDATE_SERVER_STAT="ON"
  echo "Server $SCREENNAME laeuft noch, und wird gestoppt."
  sleep 2
  screen -dr $SCREENNAME-running -X quit
fi

clear
# DOPPELSTART VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  echo -e $ROT"Error:$FARBLOS Server $SCREENNAME wird zurzeit geupdatet, bitte warte."
  exit
fi

# START WAEHREND BACKUP VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-backup` ]]; then
  echo "Backup $SCREENNAME-backup laeuft noch, Server kann nicht geupdatet werden."
  exit
fi

# CHECKEN OB HLDSUPDATETOOL VORHANDEN
if [ ! -f "steam" ]; then
  echo "Das HLdsupdatetool bzw Steam ist nicht vorhanden und wird nun herruntergeladen."
  sleep 2
 
# HLDSUPDATETOOLBEORGUNG
  wget -q http://www.steampowered.com/download/hldsupdatetool.bin
  chmod 755 hldsupdatetool.bin
  echo "yes" | ./hldsupdatetool.bin
  ./steam -command update
  clear
fi


screen -dmS $SCREENNAME-update ./steam -command update -game "$UPDATEMOD" -dir . -verify_all -retry 
if [ "$UPDATE_SERVER_STAT" == "ON" ]; then
  clear; echo -e $GELB"Der Server $SCREENNAME wurde gestoppt, und das Update wurde im Screen $SCREENNAME-update gestartet."$FARBLOS
else
  clear; echo -e $GELB"Das Update wurde im Screen $SCREENNAME-update gestartet."$FARBLOS
fi

# PRECONFIGURE_IN
SERVER_SH_PRECONFIGURE >/dev/null
}
# ---------------------------------------------------------------------------------------------



# STATUS
# ---------------------------------------------------------------------------------------------
function SERVER_SH_STATUS {
# FALLS KEIN SCREENNAMEN GEFUNDEN WURDE --- TESTING ---
if [[ ! `screen -ls |grep $SCREENNAME-` ]]; then
  echo -e $GELB"Zurzeit werden auf diesem Server keine Aktivitaeten Ausgefuehrt."$FARBLOS
  # FIXME
  exit
fi

if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  clear; echo -e $GELB"Server $SCREENNAME laeuft zurzeit."$FARBLOS
fi

# FALLS SERVER ANPINGBAR
if [ ! "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" == "DOWN" ]; then

# FALLS UNTER 10 SPIELER
  if [[ ! "$($QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $2}' |awk -F '/' '{print $2}')" == "$MAXPLAYERS" ]]; then
    echo "---"
    echo "ServerName: `$QUAKESTAT -a2s $IP:$PORT |grep -v 'ADDRESS' |awk -F "$GAMEMOD" '{print $2}' |tr -d ' '`"
    echo "ServerAddress: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $1}'`"
    echo "Map: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $4}'`"
    echo "Players: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2,$3}' |tr -d ' '`"
    echo "---"
  else
    echo "---"
    echo "ServerName: `$QUAKESTAT -a2s $IP:$PORT |grep -v 'ADDRESS' |awk -F "$GAMEMOD" '{print $2}' |tr -d ' '`"
    echo "ServerAddress: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $1}'`"
    echo "Map: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $3}'`"
    echo "Players: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2}'`"
    echo "---"
  fi
fi

# UPDATE
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  clear; echo -e $GELB"Server $SCREENNAME wird zurzeit geupdatet."$FARBLOS
fi

# BACKUP
if [[ `screen -ls |grep $SCREENNAME-backup` ]]; then
  clear; echo -e $GELB"Server $SCREENNAME wird zurzeit gebackuppt."$FARBLOS
fi

# --- EXTENSIONS --- #

# FUER JEDE EXTENSION IM ORDNER
for EXTENSION in $(find $DIR/extensions/ -type f -name "*_extension.sh" |awk -F "extensions/" {'print $2'}); do

# FALLS AUSFUEHRBAR
  if [ ! -x "$DIR/extensions/$EXTENSION" ]; then
    chmod 700 $DIR/extensions/$EXTENSION
	$DIR/extensions/$EXTENSION status
  else
    $DIR/extensions/$EXTENSION status
  fi
done
# --- EXTENSIONS --- #
}
# ---------------------------------------------------------------------------------------------



# WATCH
# ---------------------------------------------------------------------------------------------
function SERVER_SH_WATCH {
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then 
  echo "Sitzung wird geoeffnet (STRG+A+D zum Detachen." 
  echo .
  sleep 0.5
  echo ..
  sleep 0.5
  echo ...
  sleep 0.5
  screen -r $SCREENNAME-running
  clear
else 
  echo "Server $SCREENNAME laeuft nicht."
fi
}
# ---------------------------------------------------------------------------------------------



# WATCHUPDATE
# ---------------------------------------------------------------------------------------------
function SERVER_SH_WATCHUPDATE {
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  echo "Sitzung wird geoeffnet (STRG+A+D zum Detachen." 
  echo .
  sleep 0.5
  echo ..
  sleep 0.5
  echo ...
  sleep 0.5
  screen -r $SCREENNAME-update
  clear
else
  echo "Das Update $SCREENNAME-update ist entweder schon fertig, oder laeuft nicht."
fi
}
# ---------------------------------------------------------------------------------------------



# PING
# ---------------------------------------------------------------------------------------------
function SERVER_SH_PING {
echo "Bitte kurz warten, der Server wird angepingt."
sleep 0.5

if [ "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" = "DOWN" ]; then
  echo "Der Server ist nicht anpingbar somit Down oder er startet/updated noch."
  else echo "Der Server ist anpingbar und laueft."
fi
}
# ---------------------------------------------------------------------------------------------



# MAPLISTCREATE
# ---------------------------------------------------------------------------------------------
function SERVER_SH_MAPLISTCREATE {

# FALLS MAPLIST VORHANDEN
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/maplist.txt" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD/
  mv maplist.txt "maplist.txt_`$DATE`"
  MAPLIST_CFG_EXIST="1"
fi

# FALLS MAPCYCLE VORHANDEN
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD
  mv mapcycle.txt "mapcycle.txt_`$DATE`"
  MAPLIST_CFG_EXIST="1"
fi

# FALLS MAPORDNER NICHT EXISTIERT
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD/maps" ]; then
  echo "Ordner Maps ist nicht vorhanden."
  exit
fi

cd $DIR/$SRCDSDIR/$GAMEMOD/maps
echo "// Maplist.txt created by GuGy.eu Server.sh $VERSION" > $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
echo "// Mapcycle.txt created by GuGy.eu Server.sh $VERSION" > $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt
echo "" >> $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
echo "" >> $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt

# FALLS MAPLIST_INCLUDE_ONLY LEER ODER DISABLED
if [ -z "$MAPLIST_INCLUDE_ONLY" ] || [ "$MAPLIST_INCLUDE_ONLY" == "0" ] || [ "$MAPLIST_INCLUDE_ONLY" == "disabled" ]; then
# FALLS MAPLIST_EXCLUDES NICHT LEER
if ! [ -z "$MAPLIST_EXCLUDES" ] || [ "$MAPLIST_EXCLUDES" == "0" ] || [ "$MAPLIST_EXCLUDES" == "disabled" ]; then
  ls *.bsp |awk -F '.' '{print $1}' |sort |grep -Evi "$MAPLIST_EXCLUDES" >> $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
  ls *.bsp |awk -F '.' '{print $1}' |sort |grep -Evi "$MAPLIST_EXCLUDES" >> $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt
else
  ls *.bsp |awk -F '.' '{print $1}' |sort >> $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
  ls *.bsp |awk -F '.' '{print $1}' |sort >> $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt
fi
# MAPLIST_INCLUDE_ONLY ELSE
else
  ls *.bsp |awk -F '.' '{print $1}' |sort |grep -Ei "$MAPLIST_INCLUDE_ONLY" >> $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
  ls *.bsp |awk -F '.' '{print $1}' |sort |grep -Ei "$MAPLIST_INCLUDE_ONLY" >> $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt
fi

    if [ "$MAPLIST_CFG_EXIST" == "1" ]; then
      echo -e $GELB"Mapliste und Mapcycle wurden erstellt, und die alten nach Datum gebackuppt."$FARBLOS
	else
	  echo -e $GELB"Mapliste und Mapcycle wurden erstellt."$FARBLOS
	fi
}
# ---------------------------------------------------------------------------------------------



# LISTGAMES
# ---------------------------------------------------------------------------------------------
function SERVER_SH_LISTGAMES {
# CHECKEN OB STEAM VORHANDEN
if [ ! -f "steam" ]; then
  echo "Das Hldsupdatetool bzw Steam ist nicht vorhanden, und wird nun herruntergeladen."
  sleep 2
 
# HLDSUPDATETOOLBESORGUNG
  wget -q http://www.steampowered.com/download/hldsupdatetool.bin
  chmod 755 hldsupdatetool.bin
  echo "yes" | ./hldsupdatetool.bin
  ./steam -command update
fi

./steam -command list > $DIR/tmp/games_available.txt

clear; echo "Die Spieleliste wurde von Steam bezogen, und in die Datei games_available.txt geschrieben."
echo "Diese wird dir nun angezeigt."
sleep 5
cat $DIR/tmp/games_available.txt
}
# ---------------------------------------------------------------------------------------------



# BACKUP
# ---------------------------------------------------------------------------------------------
function SERVER_SH_BACKUP {

# FALLS FORCE
if [ "$FORCE_ACTIONS" == "1" ]; then
  CHECK_BEFORE_SHUTDOWN="0"
fi

# WENN CHECK AKTIVIERT
if [ "$CHECK_BEFORE_SHUTDOWN" == "1" ] || [ "$CHECK_BEFORE_SHUTDOWN" == "on" ]; then

  # FALLS SERVER ANPINGBAR
  if [ ! "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" == "DOWN" ]; then

  # FALLS UNTER 10 SPIELER
    if [[ ! "$($QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $2}' |awk -F '/' '{print $2}')" == "$MAXPLAYERS" ]]; then
      PLAYERS_ONLINE="`$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2,$3}' |tr -d ' ' |awk -F '/' {'print $1'}`"
    else
      PLAYERS_ONLINE="`$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2}' |awk -F '/' {'print $1'}`"
    fi
	
    # FALLS SPIELERZAHL UEBER NULL UND KEIN NO RESPONSE
    if [ ! "$PLAYERS_ONLINE" == "0" ] && [ ! "$PLAYERS_ONLINE" == "noresponse" ]; then
      clear; echo -e $GELB"Es sind '$PLAYERS_ONLINE' Spieler auf dem Server, Backup wird nicht fortgesetzt."$FARBLOS
	  exit
	fi
	
  fi
  
fi


# FALLS SERVER NOCH LAEUFT
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  BACKUP_SERVER_STAT="ON"
  echo "Server $SCREENNAME laeuft noch und wird gestoppt."
  sleep 2
  screen -dr $SCREENNAME-running -X quit
fi

# BACKUP WAEHREND UPDATE VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  echo -e $ROT"Error:$FARBLOS Update $SCREENNAME-update laeuft noch, Backup kann nicht gestartet werden."
 exit
fi

# DOPPELBACKUP VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-backup` ]]; then
 echo -e $ROT"Error:$FARBLOS Backup $SCREENNAME-backup laeuft noch und Backup kann nicht gestartet werden."
 exit
fi

# CHECK OB ARCHIV BEREITS BESTEHT
if [ -f "tmp/$SCREENNAME.`$DATE`.$BACKUP_FORMAT" ]; then
  echo -e $GELB"Ein Backuparchiv mit diesem Datum existiert bereits, bitte warten sie einen Augenblick"$FARBLOS
  exit
fi

# BACKUPFORMAT
# TAR
if [ "$BACKUP_FORMAT" == "tar" ]; then
  screen -dmS $SCREENNAME-backup nice -n 19 tar cfv tmp/$SCREENNAME.`$DATE`.tar $BACKUP_FILES
# TAR.GZ
elif [ "$BACKUP_FORMAT" == "tar.gz" ]; then
  screen -dmS $SCREENNAME-backup nice -n 19 tar cfvz tmp/$SCREENNAME.`$DATE`.tar.gz $BACKUP_FILES
# TAR.BZ2  
elif [ "$BACKUP_FORMAT" == "tar.bz2" ]; then
  screen -dmS $SCREENNAME-backup nice -n 19 tar cfvj tmp/$SCREENNAME.`$DATE`.tar.bz2 $BACKUP_FILES
# FALLS NICHT ANGEGEBEN
elif [ -z "$BACKUP_FORMAT" ]; then
  echo -e $ROT"Error:$FARBLOS Backup Format nicht angegeben."
  exit
# FALLS FALSCH ANGEGEBEN
else
  echo -e $ROT"Error:$FARBLOS Falsches Backup-Format."
  exit
fi

if [ "$BACKUP_SERVER_STAT" == "ON" ]; then
  clear; echo -e $GELB"Der Server $SCREENNAME wurde gestoppt, und das Backup wurde im Screen $SCREENNAME-backup gestartet."$FARBLOS
else
  clear; echo -e $GELB"Das Backup wurde im Screen $SCREENNAME-backup gestartet."$FARBLOS
fi
}
# ---------------------------------------------------------------------------------------------



# PRECONFIGURE
# ---------------------------------------------------------------------------------------------
function SERVER_SH_PRECONFIGURE {

# PRECONF ACTIVE CHECK
if [ ! "$PRECONFIGURE" == "1" ]; then
  echo -e $ROT"Error:$FARBLOS Variable Preconfigure ist nicht auf 1 gesetzt."
  exit
fi

# ORDNERCHECK
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD/cfg" ]; then
  echo "$DIR/$SRCDSDIR/$GAMEMOD/cfg existiert nicht."
  exit
else
  cd $DIR/$SRCDSDIR/$GAMEMOD/cfg
fi

# PRECONFDEL UND BACKUP
if [ "$PRECONFDEL" == "1" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD/cfg
  
    if [ -f "$CFG1" ]; then
      mv $CFG1 "$CFG1-`$DATE`"
	  echo "CFG '$CFG1' wurde gebackuppt."
	fi
	
	if [ -f "$CFG2" ]; then
      mv $CFG2 "$CFG2-`$DATE`"
	  echo "CFG '$CFG2' wurde gebackuppt."
	fi

fi

# CFG EXIST LOCK AUF 0 SETZEN
CFG_EXIST_LOCK="0"

# AUTOEXEC.CFG
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/cfg/$CFG1" ]; then
  echo -e $GELB"CFG $CFG1 schon vorhanden."$FARBLOS
  CFG_EXIST_LOCK="$[CFG_EXIST_LOCK+1]"
fi

# SERVER.CFG
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/cfg/$CFG2" ]; then
  echo -e $GELB"CFG $CFG2 schon vorhanden."$FARBLOS
  CFG_EXIST_LOCK="$[CFG_EXIST_LOCK+1]"
fi

# CFG EXIST LOCK CHECKEN
if [ ! "$CFG_EXIST_LOCK" == "0" ]; then
  exit  
fi

# TEMPLATE EXIST LOCK AUF 0 SETZEN
TEMPLATE_EXIST_LOCK="0"

# CONFIG - AUTOEXEC.CFG
if [[ `wget -q -O- $TEMPLATESURL/$GAMEMOD/$CFG1` ]]; then
  wget -q $TEMPLATESURL/$GAMEMOD/$CFG1
  echo -e $GELB"CFG '$CFG1' wurde heruntergeladen."$FARBLOS
else 
  echo "CFG '$CFG1' konnte nicht heruntergeladen werden, anscheinend ist keine CFG fuer den GameMod '$GAMEMOD' verfuegbar."
  TEMPLATE_EXIST_LOCK="$[CFG_EXIST_LOCK+1]"
fi

# CONFIG - SERVER.CFG
if [[ `wget -q -O- $TEMPLATESURL/$GAMEMOD/$CFG2` ]]; then
  wget -q $TEMPLATESURL/$GAMEMOD/$CFG2
  echo -e $GELB"CFG '$CFG2' wurde heruntergeladen."$FARBLOS
else
  echo "CFG '$CFG1' konnte nicht heruntergeladen werden, anscheinend ist keine CFG fuer den GameMod '$GAMEMOD' verfuegbar."
  TEMPLATE_EXIST_LOCK="$[CFG_EXIST_LOCK+1]"
fi

# TEMPLATE EXIST LOCK CHECKEN
if [ ! "$TEMPLATE_EXIST_LOCK" == "0" ]; then
  echo -e $GELB"Es traten Fehler beim downloaden der Configs auf."$FARBLOS
else
  echo -e $GELB"CFGS wurden in $DIR/$SRCDSDIR/$GAMEMOD/cfg angelegt."$FARBLOS
fi
}
# ---------------------------------------------------------------------------------------------



# UPDATEVERSION
# ---------------------------------------------------------------------------------------------
function SERVER_SH_UPDATEVERSION {
VERSIONCHECK_LOCAL="$VERSION" 
VERSIONCHECK_REMOTE="`wget -q -O- $VERSIONURL | fgrep  Version:`"
FEATURES="`wget -q -O- $FEATURESURL | grep -v '#'`"
CONFLOCK="`wget -q -O- $VERSIONURL | fgrep  LOCK=1`"

# UPDATE LOCK AUF 0 SETZEN
UPDATE_LOCK="0"

# FALLS VERSIONURL NICHT ABRUFBAR
if [[ ! $VERSIONCHECK_REMOTE ]]; then
  VERSIONCHECK_REMOTE="Version konnte nicht abgerufen werden"
  UPDATE_LOCK="$[$UPDATE_LOCK+1]"
fi

# FALLS FEATURES NICHT ABRUFBAR 
if [[ ! $FEATURES ]]; then
  FEATURES="Features konnten nicht abgerufen werden."
  UPDATE_LOCK="$[$UPDATE_LOCK+1]"
fi


echo "Ihre Version:    $VERSION"
echo "Neuste Version:  $VERSIONCHECK_REMOTE"


if [ "$VERSIONCHECK_LOCAL" == "$VERSIONCHECK_REMOTE" ]; then
  echo "Sie haben die neuste Version." 
  exit
else
  echo ""
  echo -e $GELB"Sie haben eine aeltere Version dieses Scriptes und sollten updaten."$FARBLOS
  echo "Infos und neue Features sind:"
  echo ""
  echo "$FEATURES"
fi


# FALLS UPGRADEPAKET NICHT VORHANDEN
if [[ ! `wget -q -O- $UPDATEURL` ]]; then
  echo ""
  echo -e $GELB"Sorry der Contentserver ist zurzeit nicht erreichbar, oder das Upgradepaket fehlt."$FARBLOS
  UPDATE_LOCK="$[$UPDATE_LOCK+1]"
fi
  
  
# FALLS UPDATE LOCK NICHT 0
if [ ! "$UPDATE_LOCK" == "0" ]; then
  echo ""
  echo -e $ROT"Error:$FARBLOS Es gab '$UPDATE_LOCK' Fehler, Update kann nicht fortgefuehrt werden."
  exit
fi


# CONFIGLOCK
if [[ $CONFLOCK ]]; then
 echo ""
 echo -e $GELB"Wichtig:$FARBLOS Das Update der Vorversion auf $VERSIONCHECK_REMOTE beinhaltet die Configdatei."
 echo "Sie sollten nun daher die Configdatei loeschen oder umbennen, zB per FTP/SFTP/SSH bevor sie das Update zustimmen."
 echo "Andersfalls wird die Config in den TMP Ordner gebackuppt"
fi


# --- 
echo "" 
echo -n "Wollen sie jetzt Updaten? yes/no: "
read UPDATEQUESTION
if [ "$UPDATEQUESTION" == "yes" ]; then
  wget -q $UPDATEURL
  
    # Archivcheck
    if [ ! -f "server.tar.gz" ]; then
      clear; echo -e $ROT"Error:$FARBLOS Das Updatearchiv konnte nicht gefunden werden. Abbruch"
      exit
    fi
	
# ---
# SERVER.SH BACKUPPEN
if [ -f "server.sh" ]; then
  mv server.sh  server.sh_`$DATE`
  mv server.sh_* $DIR/tmp
fi

# SERVER.CONF BACKUPPEN
if [[ $CONFLOCK ]]; then

  if [ -f "server.conf" ]; then
    mv server.conf  server.conf_`$DATE`
    mv server.conf_* $DIR/tmp
  fi

fi
  
if [ -f "$DIR/server.conf" ]; then
 # CONFIGMOVE IF EXIST
 # FIXME
  tar xvf server.tar.gz --exclude server.conf --exclude make
  rm -f server.tar.gz
else
  tar xvf server.tar.gz --exclude make
  rm -f server.tar.gz
fi

  clear; echo -e $GELB"Update war erfolgreich"$FARBLOS
else 
  clear; echo -e $GELB"Update abgebrochen"$FARBLOS
  
fi
}
# ---------------------------------------------------------------------------------------------



# VERSION
# ---------------------------------------------------------------------------------------------
function SERVER_SH_VERSION {
echo "Ihre Version:    $VERSION"
}
# ---------------------------------------------------------------------------------------------



# ADDONISNTALL
# ---------------------------------------------------------------------------------------------
function SERVER_SH_ADDONINSTALL {

# FALSCHEINGABE
if [ "$1" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Falscheingabe"
  echo "     Usage: addoninstall Addonname"
  exit
fi

# ORDNERCHECK
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
  echo "$DIR/$SRCDSDIR/$GAMEMOD existiert nicht."
  exit
else
  cd $DIR/$SRCDSDIR/$GAMEMOD
fi

# FALLS SCHON VORHANDEN
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/$1.addonlist" ]; then
  echo -ne $GELB"Das Addon '$1' scheint schon installiert zu sein.$FARBLOS
  [- wollen sie es dennoch installieren? yes/no: "
  read ADDON_OVERWRITE_QUESTION
  
  
    if [ ! "$ADDON_OVERWRITE_QUESTION" == "yes" ]; then
      clear; echo -e $GELB"Das Addon '$1' Wurde nicht installiert"$FARBLOS
      exit
    fi
   
fi

# DOWNLOAD DES ADDONS
clear; echo -e $GELB"Einen Moment bitte."$FARBLOS

if [[ `wget -q -O- $ADDONURL/$1.tar.bz2` ]]; then
  clear; echo -e $GELB"Addon '$1' wird herruntergeladen"$FARBLOS
  wget -q  $ADDONURL/$1.tar.bz2
  else echo -e $ROT"Addon '$1.tar.bz2' ist nicht auf dem Masterserver vorhanden."$FARBLOS 
  exit
fi
# ---

# VERARBEITUNG DES ADDONS
if [ -f "$1.tar.bz2" ]; then
  tar xfvj $1.tar.bz2 > addoninstall_$1.log
  rm -f $1.tar.bz2
  
    # ADDONINSTALL FILE
    if [ -f "addoninstall.sh" ]; then
	  chmod 755 addoninstall.sh
	  ./addoninstall.sh
	  rm -f addoninstall.sh
	fi
  
  clear; echo -e $GELB"Das Addon '$1' wurde erfolgreich installiert."$FARBLOS
	
else
  echo -e $GELB"Das Addon '$1.tar.bz2' existiert nicht!"$FARBLOS
  exit
fi
}
# ---------------------------------------------------------------------------------------------



# ADDONREMOVE
# ---------------------------------------------------------------------------------------------
function SERVER_SH_ADDONREMOVE {

# FALSCHEINGABE
if [ "$1" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Falscheingabe"
  echo "     Usage: addonremove Addonname"
  exit
fi

# ORDNERCHECK
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
  echo "$DIR/$SRCDSDIR/$GAMEMOD existiert nicht."
  exit
else
  cd $DIR/$SRCDSDIR/$GAMEMOD
fi

# PRUFEN UND DEINSTALLIEREN DES ADDONS 
if [ ! -f "$DIR/$SRCDSDIR/$GAMEMOD/$1.addonlist" ]; then
  echo -e $GELB"Die Addondatei '$1.addonlist' existiert nicht!"$FARBLOS
  exit
fi

echo -e $GELB"Einen Moment bitte."$FARBLOS
sleep 1

# LOESCHFUNKTION
cat $DIR/$SRCDSDIR/$GAMEMOD/$1.addonlist | tr -d '\r' | tr -s '\n' | while read ADDONLIST; do
  rm -Rf "$ADDONLIST"
done

rm -f $DIR/$SRCDSDIR/$GAMEMOD/$1.addonlist

# FALLS INSTALLER LOG VORHANDEN
if [ -f "addoninstall_$1.log" ]; then
 rm -f addoninstall_$1.log
fi

# ---
clear; echo -e $GELB"Addon '$1' wurde geloescht"$FARBLOS
}
# ---------------------------------------------------------------------------------------------



# ADDONLIST
# ---------------------------------------------------------------------------------------------
function SERVER_SH_ADDONLIST {

# ADDONLISTCHECK
if [[ ! `wget -q -O- $ADDONURL/addons.txt` ]]; then
  echo -e $ROT"Addonliste ist nicht auf dem Masterserver vorhanden."$FARBLOS 
  exit
fi

echo -e $GELB"Folgende Addons lassen sich ueber den Installer installieren"$FARBLOS
echo ""
echo "---"
echo "`wget -q -O- $ADDONURL/addons.txt`"
echo "---"
}
# ---------------------------------------------------------------------------------------------



# ADDONINSTALLED
# ---------------------------------------------------------------------------------------------
function SERVER_SH_ADDONS {

# ORDNERCHECK
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
  echo "$DIR/$SRCDSDIR/$GAMEMOD existiert nicht."
  exit
else
  cd $DIR/$SRCDSDIR/$GAMEMOD
fi

# ADDONCHECK
if [[ `ls $DIR/$SRCDSDIR/$GAMEMOD/*.addonlist` ]]; then
  ls *.addonlist |awk -F '.' '{print $1}' | sort > $DIR/addonslist.tmp
else 
  clear; echo -e $GELB"Es scheinen keine Addons installiert zu sein"$FARBLOS
  exit
fi


echo -e $GELB"Folgende Addons sind installiert"$FARBLOS
echo ""
echo "---"
echo "`cat $DIR/addonslist.tmp | tr -t [a-z] [A-Z]`"
echo "---"
rm -f $DIR/addonslist.tmp
}
# ---------------------------------------------------------------------------------------------



# ADDONVERSION
# ---------------------------------------------------------------------------------------------
function SERVER_SH_ADDONVERSION {
# FIXME
if [[ `ls $DIR/$SRCDSDIR/$GAMEMOD/*.version` ]]; then
  for addon in $(ls $DIR/$SRCDSDIR/$GAMEMOD/*.version); do
    if [ -f "$addon" ]; then
      echo "${addon%????????}" | awk -F "$DIR/$SRCDSDIR/$GAMEMOD/" '{print $2}' | tr -t [a-z] [A-Z]
	  echo "-----------"
      cat "$addon"
      echo -e "\n-----------\n"
    else
      echo "Addoninformationen fuer $addon nicht verfuegbar"
    fi
  done
else
  echo "Keine Addons installiert."
fi
}
# ---------------------------------------------------------------------------------------------



# ADDONBACKUP
# ---------------------------------------------------------------------------------------------
function SERVER_SH_ADDONBACKUP {

# FALSCHEINGABE
if [ "$1" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Falscheingabe"
  echo "     Usage: addonbackup Addonname"
  exit
fi

# ORDNERCHECK
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
  echo "$DIR/$SRCDSDIR/$GAMEMOD existiert nicht."
  exit
else
  cd $DIR/$SRCDSDIR/$GAMEMOD
fi

# PRUFEN UND DEINSTALLIEREN DES ADDONS 
if [ ! -f "$DIR/$SRCDSDIR/$GAMEMOD/$1.addonlist" ]; then
  echo -e $GELB"Die Addondatei '$1.addonlist' existiert nicht!"$FARBLOS
  exit
fi

# CHECK OB ARCHIV BEREITS BESTEHT
if [ -f "$DIR/tmp/$1-`$DATE`.tar.gz" ]; then
  echo -e $GELB"Ein Backuparchiv mit diesem Datum existiert bereits, bitte warten sie einen Augenblick"$FARBLOS
  exit
fi

echo -e $GELB"Einen Moment bitte."$FARBLOS
sleep 1

# PACKEN
tar cfz $DIR/tmp/addon_$1-`$DATE`.tar.gz -T $1.addonlist $1.addonlist


# ---
clear; echo -e $GELB"Addon '$1' wurde gebackuppt"$FARBLOS
}
# ---------------------------------------------------------------------------------------------



# CLEANUP
# ---------------------------------------------------------------------------------------------
function SERVER_SH_CLEANUP {

# ZTMP
# ---------------
# CHECK OB AKTIVIERT
if [ "$CLEANUP_ZTMP" == "1" ] || [ "$CLEANUP_ZTMP" == "on" ]; then
  echo "Loesche alte Ztmp Dateien..."
  # COUNT FILES
  # CHECK OB ORDNER VORHANDEN SourceTv
  if [ -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
    find $DIR/$SRCDSDIR/$GAMEMOD/ -name "*.ztmp" -mtime +$LOGTIME | wc -l > $DIR/tmp/cleanup_ztmp_count.tmp
    find $DIR/$SRCDSDIR/$GAMEMOD/ -name "*.ztmp" -mtime +$LOGTIME $LOGEXEC
  fi
  
  
  # AMOUNT OF REMOVED FILES
  if [ -f "$DIR/tmp/cleanup_ztmp_count.tmp" ]; then
    CLEANUP_ZTMP_COUNT="`cat $DIR/tmp/cleanup_ztmp_count.tmp`"
    rm -f $DIR/tmp/cleanup_ztmp_count.tmp
  else
    CLEANUP_ZTMP_COUNT="Error beim lesen der Datei."
  fi
  sleep 1
else
  CLEANUP_ZTMP_COUNT="Deaktiviert"
fi
      
# ---------------


# LOGS
# ---------------
# CHECK OB AKTIVIERT
if [ "$CLEANUP_LOGS" == "1" ] || [ "$CLEANUP_LOGS" == "on" ]; then
  echo "Loesche alte Log Dateien..."
  # COUNT FILES
  # CHECK OB ORDNER VORHANDEN LOGS
  if [ -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
    find $DIR/$SRCDSDIR/$GAMEMOD/ -type f -name "*.log" -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_log_count.tmp
    find $DIR/$SRCDSDIR/$GAMEMOD/ -type f -name "*.log" -mtime +$LOGTIME $LOGEXEC
  fi


  # AMOUNT OF REMOVED FILES
  if [ -f "$DIR/tmp/cleanup_log_count.tmp" ]; then
    CLEANUP_LOG_COUNT="`cat $DIR/tmp/cleanup_log_count.tmp`"
    rm -f $DIR/tmp/cleanup_log_count.tmp
  else
   CLEANUP_LOG_COUNT="Error beim lesen der Datei."
  fi
  sleep 1
else
  CLEANUP_LOG_COUNT="Deaktiviert"
fi
# ---------------


# DOWNLOADS
# ---------------
# CHECK OB AKTIVIERT
if [ "$CLEANUP_DOWNLOADS" == "1" ] || [ "$CLEANUP_DOWNLOADS" == "on" ]; then
  echo "Loesche alte Download Dateien..."
  # COUNT FILES
  # CHECK OB ORDNER VORHANDEN DOWNLOADS
  if [ -d "$DIR/$SRCDSDIR/$GAMEMOD/downloads" ]; then
    find $DIR/$SRCDSDIR/$GAMEMOD/downloads/ -type f -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_downloads_count.tmp
    find $DIR/$SRCDSDIR/$GAMEMOD/downloads/ -type f -mtime +$LOGTIME $LOGEXEC
  fi

  # AMOUNT OF REMOVED FILES
  if [ -f "$DIR/tmp/cleanup_downloads_count.tmp" ]; then
    CLEANUP_DOWNLOADS_COUNT="`cat $DIR/tmp/cleanup_downloads_count.tmp`"
    rm -f $DIR/tmp/cleanup_downloads_count.tmp
  else
    CLEANUP_DOWNLOADS_COUNT="Error beim lesen der Datei."
  fi
  sleep 1
else
  CLEANUP_DOWNLOADS_COUNT="Deaktiviert"
fi
# ---------------


# DOWNLOADS LISTS
# ---------------
# CHECK OB AKTIVIERT
if [ "$CLEANUP_DOWNLOADLISTS" == "1" ] || [ "$CLEANUP_DOWNLOADLISTS" == "on" ]; then
  echo "Loesche alte DownloadLists..."
  # COUNT FILES
  # CHECK OB ORDNER VORHANDEN DOWNLOADLISTS
  if [ -d "$DIR/$SRCDSDIR/$GAMEMOD/DownloadLists" ]; then
    find $DIR/$SRCDSDIR/$GAMEMOD/DownloadLists/ -type f -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_downloads_lists_count.tmp
    find $DIR/$SRCDSDIR/$GAMEMOD/DownloadLists/ -type f -mtime +$LOGTIME $LOGEXEC
  fi


  # AMOUNT OF REMOVED FILES
  if [ -f "$DIR/tmp/cleanup_downloads_lists_count.tmp" ]; then
    CLEANUP_DOWNLOADS_LISTS_COUNT="`cat $DIR/tmp/cleanup_downloads_lists_count.tmp`"
    rm -f $DIR/tmp/cleanup_downloads_lists_count.tmp
  else
    CLEANUP_DOWNLOADS_LISTS_COUNT="Error beim lesen der Datei."
  fi
  sleep 1
else
  CLEANUP_DOWNLOADS_LISTS_COUNT="Deaktiviert"
fi
# ---------------


# SOURCETV
# ---------------
# CHECK OB AKTIVIERT
if [ "$CLEANUP_SOURCETV" == "1" ] || [ "$CLEANUP_SOURCETV" == "on" ]; then
  echo "Loesche alte Demo/SourceTv Dateien..."
  # COUNT FILES
  # CHECK OB ORDNER VORHANDEN SOURCETV
  if [ -d "$DIR/$SRCDSDIR/$GAMEMOD" ]; then
    find $DIR/$SRCDSDIR/$GAMEMOD/ -type f -name "*.dem" -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_demo_count.tmp
    find $DIR/$SRCDSDIR/$GAMEMOD/ -type f -name "*.dem" -mtime +$LOGTIME $LOGEXEC
  fi

  # AMOUNT OF REMOVED FILES
  if [ -f "$DIR/tmp/cleanup_demo_count.tmp" ]; then
    CLEANUP_DEMO_COUNT="`cat $DIR/tmp/cleanup_demo_count.tmp`"
    rm -f $DIR/tmp/cleanup_demo_count.tmp
  else
    CLEANUP_DEMO_COUNT="Error beim lesen der Datei."
  fi
  sleep 1
else
  CLEANUP_DEMO_COUNT="Deaktiviert"
fi
# ---------------


# BACKUPS
# ---------------
# CHECK OB AKTIVIERT
if [ "$CLEANUP_BACKUPS" == "1" ] || [ "$CLEANUP_BACKUPS" == "on" ]; then
  echo "Loesche alte Backup Dateien..."
  # COUNT FILES
  find $DIR/tmp/ -type f -name "*.tar*" -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_backup_count.tmp
  find $DIR/tmp/ -type f -name "*.tar*" -mtime +$LOGTIME $LOGEXEC

  # AMOUNT OF REMOVED FILES
  if [ -f "$DIR/tmp/cleanup_backup_count.tmp" ]; then
    CLEANUP_BACKUP_COUNT="`cat $DIR/tmp/cleanup_backup_count.tmp`"
    rm -f $DIR/tmp/cleanup_backup_count.tmp
  else
    CLEANUP_BACKUP_COUNT="Error beim lesen der Datei."
  fi
  sleep 1
else
  CLEANUP_BACKUP_COUNT="Deaktiviert"
fi
# ---------------

clear; echo -e $GELB"Server wurde aufgeraeumt."$FARBLOS

echo ""
echo "ZTMP:         '$CLEANUP_ZTMP_COUNT'"
echo "LOG:          '$CLEANUP_LOG_COUNT'"
echo "DOWNLOAD      '$CLEANUP_DOWNLOADS_COUNT'"
echo "DOWNLOADLIST: '$CLEANUP_DOWNLOADS_LISTS_COUNT'"
echo "SOURCETV:     '$CLEANUP_DEMO_COUNT'"
echo "BACKUP        '$CLEANUP_BACKUP_COUNT'"


}
# ---------------------------------------------------------------------------------------------




# CRONJOB
# ---------------------------------------------------------------------------------------------
function SERVER_SH_CRONTAB {
echo "Geben sie bitte hier die Stunde und Minute des taeglichen Cronjobs ein."
echo ""
echo -n "Stunde des Cronjobs {0-23}: "
  read CRONJOB_HOUR
# clear
echo -n "Minute des Cronjobs {0-59}: " 
  read CRONJOB_MINUTE
# clear
echo -n "Kommentar fuer den Cronjob {Ohne #}: " 
  read CRONJOB_COMMENT
# clear 
echo -n "Aktion des Cronjobs {update/restart...}: "
  read CRONJOB_ACTION
 clear 

# IF CRON ALREADY EXIST
if [ -f "$DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION" ]; then
  echo -e $GELB"Eine Cronjob-file mit dieser Aufgabe existiert bereits."$FARBLOS
  echo -n "Wollen sie diese Datei ueberschreiben? yes/no: "
  read CRONJOB_OVERWRITE_QUESTION
  
    if [ "$CRONJOB_OVERWRITE_QUESTION" == "no" ]; then
	  clear; echo "Ihre Wahl, wir brechen ab."
	  exit
    fi
	
  clear
fi
# --
 
# SCRIPT_INPUT
if [ "$CRON_LOGGING" == "1" ]; then
  echo "#!/bin/bash
  $DIR/server.sh $CRONJOB_ACTION >> $DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION.log" > $DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION
else
  echo "#!/bin/bash
  $DIR/server.sh $CRONJOB_ACTION" > $DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION
fi


if [ -f "$DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION" ]; then
  chmod 755 $DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION
fi

# USER_OUTPUT
echo -e "Cronjob-file wurde generiert, tragen sie nun folgenden Code mit $GELB crontab -e $FARBLOS ein."
echo "Achten sie darauf mittels Enter eine leere Zeile folgend dem Befehl zu erzeugen."
echo ""
echo "# $CRONJOB_COMMENT $CRONJOB_HOUR:$CRONJOB_MINUTE Uhr
$CRONJOB_MINUTE $CRONJOB_HOUR * * * $DIR/tmp/cron-$SCREENNAME-$CRONJOB_ACTION"
}
# ---------------------------------------------------------------------------------------------




# MAKEVDF
# ---------------------------------------------------------------------------------------------
function SERVER_SH_MAKEVDF {

case "$1" in
# METAMOD
# ---------------------------------------------------
mm|meta|metamod)
if [ -d "$DIR/$SRCDSDIR/$GAMEMOD/addons/metamod" ]; then
  echo "\"Plugin\"
  {
  \"file\"	\"../$GAMEMOD/addons/metamod/bin/server\"
  }
  " > $DIR/$SRCDSDIR/$GAMEMOD/addons/metamod.vdf
  echo -e $GELB"metamod.vdf wurde angelegt"$FARBLOS
else
      echo "Metamodordner existiert nicht."
fi
;;
# ---------------------------------------------------




# SOURCEMOD
# ---------------------------------------------------
sm|sourcemod)
if [ -d "$DIR/$SRCDSDIR/$GAMEMOD/addons/metamod" ]; then
   echo '"Metamod Plugin"
  {
  "alias"		"sourcemod"
  "file"		"addons/sourcemod/bin/sourcemod_mm"
  }
  ' > $DIR/$SRCDSDIR/$GAMEMOD/addons/metamod/sourcemod.vdf
  echo -e $GELB"sourcemod.vdf wurde angelegt"$FARBLOS
else
  echo "Metamodordner existiert nicht."
fi
;;
# ---------------------------------------------------




# MANI ADMIN
# ---------------------------------------------------
mani|mani_admin)
if [ -d "$DIR/$SRCDSDIR/$GAMEMOD/addons/mani_admin_plugin" ]; then
  echo "\"Plugin\"
  {
  \"file\" \"../$GAMEMOD/addons/mani_admin_plugin_i486\"
  }
  " > $DIR/$SRCDSDIR/$GAMEMOD/addons/mani_admin_plugin.vdf
  echo -e $GELB"mani_admin_plugin.vdf wurde angelegt"$FARBLOS
else
  echo "mani_admin_plugin Ordner existiert nicht."
fi
;;
# ---------------------------------------------------



*)
echo -e $ROT"Error:$FARBLOS Es wurde kein oder ein falscher Mod angegeben"
echo -e "       Nutzung: sm|sourcemod - mm|metamod - mani|mani_admin"
;;  

esac  
exit
  
}
# ---------------------------------------------------------------------------------------------




# WATCHLOG
# ---------------------------------------------------------------------------------------------
function SERVER_SH_WATCHLOG {
if [ -f "$DIR/$SRCDSDIR/screenlog.0" ]; then
  echo -e $GELB"--- Log beginnt ---"$FARBLOS
  more $DIR/$SRCDSDIR/screenlog.0
  echo -e $GELB"--- Log zu Ende ---"$FARBLOS
else
  echo "Kein Screenlog vorhanden."
fi
}
# ---------------------------------------------------------------------------------------------




# HELP
# ---------------------------------------------------------------------------------------------
function SERVER_SH_HELP {
clear
echo "Ausfuehrbare Befehle"
echo "Usage: $0 {Code/Befehl}"
echo "Code | Befehl | Beschreibung"
echo "____________________________"
echo ""
echo "1)  start                     - Startet den Gameserver."
echo "2)  stop                      - Stoppt den Gameserver."
echo "3)  restart                   - Restartet den Gameserver."
echo "4)  update|install            - Updatet/Installiert den Gameserver."
echo "5)  status                    - Zeigt den Status des Gameservers."
echo "6)  watch                     - Oeffnet die Screensession des Gameservers."
echo "7)  watchupdate               - Oeffnet die Screensession des Updaters."
echo "8)  ping                      - Pingt den Server an und checkt ob er online ist."
echo "9)  maplistcreate             - Erstellt eine maplist/mapcycle\.txt aller .bsp Dateien in standartgemaess srcdsdir/moddir/maps."
echo "10) listgames                 - Listet alle Spiele auf die ueber Steam bezogen werden koennen und schreibt sie in tmp/games_available.txt"
echo "11) backup                    - Backuppt den Gameserver in das TMP-Verzeichnis mit Angabe des Datumsformates."
echo "12) preconfigure              - Laed eine Minimale Server/Autoexec\.cfg vom eingetragenen Masterserver nach standartgemaess srcdsdir/moddir/cfg."
echo "13) updateversion             - Prueft die Locale Scriptversion und vergleicht diese mit dem Updateserver"
echo "                             [- falls eine neue Version vorhanden ist kann sie nach zustimmung geupdatet werden."
echo "                             [- Die alte Version geht dabei nicht verloren."
echo "14) version                   - Zeigt lediglich die Version an."
echo "15) addoninstall              - Laed ein Addon Von dem in der Config eingetragenen Masterserver und Installiert es."
echo "16) addonremove               - Loescht ein Addon das Vom Masterserver bezogen werden kann."
echo "17) addonlist                 - Listet alle Addons auf die ueber den Installer bezogen werden koennen"
echo "18) addons|addonlist_local    - Listet alle Addons auf die ueber den Installer installiert wurden"
echo "19) cleanup                   - Entfernt alte Logs, SourceTV Demos, Downloads und Ztmp Datein."
echo "20) cronjob|crontab|cron      - Erstellt einen Taeglichen Cronjob"
echo "21) makevdf|vdf               - Erstellt .vdf Dateien fuer verschiedene Addons."
echo ""
echo ""
echo "22) help|h                    - Zeigt diese Hilfe an"
echo ""
echo ""
echo "Option { -c Funktion}         - Unterdrueckt die Shellfarben."
echo "Option { -f Funtkion}         - Erzwingt Funktion."
}


case "$1" in
start|1)
SERVER_SH_START
;;

stop|2)
SERVER_SH_STOP
;;

restart|3)
SERVER_SH_RESTART
;;

update|install|4)
SERVER_SH_UPDATE
;;

status|5) 
SERVER_SH_STATUS
;;

watch|6)
SERVER_SH_WATCH
;;

watchupdate|7)
SERVER_SH_WATCHUPDATE
;;

ping|8)
SERVER_SH_PING
;;

maplistcreate|9)
SERVER_SH_MAPLISTCREATE
;;

listgames|10)
SERVER_SH_LISTGAMES
;;

backup|11)
SERVER_SH_BACKUP
;;

preconfigure|12)
SERVER_SH_PRECONFIGURE
;;

updateversion|13)
SERVER_SH_UPDATEVERSION
;;

version|14)
SERVER_SH_VERSION
;;

addoninstall|15)
SERVER_SH_ADDONINSTALL $2
;;

addonremove|16)
SERVER_SH_ADDONREMOVE $2
;;

addonlist|17)
SERVER_SH_ADDONLIST
;;

addons|addonlist_local|18)
SERVER_SH_ADDONS
;;

addonversion)
SERVER_SH_ADDONVERSION
;;

addonbackup)
SERVER_SH_ADDONBACKUP $2
;;

cleanup|19)
SERVER_SH_CLEANUP
;;

cronjob|crontab|cron|20)
SERVER_SH_CRONTAB
;;

makevdf|vdf|21)
SERVER_SH_MAKEVDF $2
;;

watchlog|logwatch|log)
SERVER_SH_WATCHLOG
;;

h|help|22)
SERVER_SH_HELP
;;


*)
echo "Usage: $0 {start|stop|restart|update|status|watch|watchupdate|ping|maplistcreate|listgames|backup|help}"
;;

esac
exit 



