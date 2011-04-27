#!/bin/bash
# 
#
# Ueber Das Script
# ---------------------------------------------------------------------------------------------
# Name:    - Gameserververwaltungsscript fuer Orangebox-Games 
# Version: - 0.2.4-Beta2
# Author:  - Impact, http://gugy.eu
# Lizens:  - GPLv3
# E-Mail:  - support@gugy.eu
# Web:     - http://gugyclan.eu
# Datum:   - 22.04.2011
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

VERSION="Version: 0.2.4-Beta2"

# FARBEN
GELB="\033[1;33m"
ROT="\033[0;31m"
FARBLOS="\033[0m"
# ---

# STARTUP_LOCK auf 0 SETZEN
STARTUP_LOCK="0"

# SCRIPTAUFRUF VON UEBERALL
cd $(dirname $0)


 clear
# CONFIGCHECK
if [ -f "server.conf" ]; then
  chmod 755 server.conf
  source server.conf
else
  echo -e $ROT"Error:$FARBLOS Configdatei fehlt oder Pfad ist falsch."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
fi

# ADMINCHECK
if [ "`whoami`" == "root" ]; then
  echo "Verantwortungsvolle Admins starten Gameserver nicht mit dem root User."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
fi

 # QSTATCHECK
if [[ ! `which $QUAKESTAT` ]]; then
  echo -e $ROT"Error:$FARBLOS Paket $QUAKESTAT nicht gefunden,"
  echo "sie sollten es installieren oder die Variable in der Kopfzeile anpassen."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
fi

# DIRCHECK
if [ "$DIR" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde kein Dir angegeben."
  echo    "    [- Es wurde folgendes Verzeichnis ausgelesen"
  echo -e $GELB"    [- $(pwd)"$FARBLOS
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
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
fi

# SCRENNNAMECHECK
if [ "$SCREENNAME" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde kein Screenname angegeben."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
fi

# IPCHECK
DEVICE="eth0"
INET_ADRESS="`/sbin/ifconfig $DEVICE |grep "inet addr:"| awk '{ print $2}' |awk -F: '{print $2}'`"

if [ "$IP" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde keine IP angegeben."
  echo -e "    [- Es wurde folgende ipv4-Adresse ausgelesen"
  echo -e $GELB"    [- $INET_ADRESS"$FARBLOS
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
fi

if [ "$PORT" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Es wurde kein Port angegeben."
  # STARTUP_LOCK SETZEN
  STARTUP_LOCK="$[$STARTUP_LOCK+1]"
fi

# DIRWRAPPER
if [ ! "$DIR_DOESNT_EXIST" == "1" ];then

    # EXTENSIONDIRCHECK
    if [ ! -d "$DIR/extensions" ]; then 
      mkdir $DIR/extensions
    fi

    # TMPDIRCHECK
    if [ ! -d "$DIR/tmp" ]; then 
      mkdir $DIR/tmp
    fi
	
	# TEMPLATEDIRCHECK # --- Next Version ---
#    if [ ! -d "$DIR/templates" ]; then 
#      mkdir $DIR/templates
#    fi
fi

 # STARTUP_LOCK CHECKEN
 if [ ! "$STARTUP_LOCK" == "0" ]; then
   echo ""
   echo -e $GELB"Es wurden mindestens '$STARTUP_LOCK' Probleme gefunden, Start verhindert."$FARBLOS
   exit
fi

 
# START - BEGINN DES SCRIPTES
# ---------------------------------------------------------------------------------------------
 case "$1" in
start|1)
# GAMECHECK
if [ ! -d "$DIR/$SRCDSDIR" ]; then
  echo -e $ROT"Error:$FARBLOS $SRCDSDIR existiert nicht."
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

# DOPPELBACKUP VERHINDERN
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  echo -e $ROT"Error:$FARBLOS Server $SCREENNAME-running laeuft noch, Server kann nicht gestartet werden."
  exit
fi

# SCREENLOGCHECK
if [ -f "$DIR/$SRCDSDIR/screenlog.0" ]; then 
  cd $DIR/$SRCDSDIR; mv screenlog.0 $LOGDIR
  cd $DIR/$SRCDSDIR/$LOGDIR
  mv screenlog.0 "screenlog.0_`$DATE`"
fi

# LOGTIMECHECK
if [[ `find $DIR/$SRCDSDIR/$LOGDIR/ -type f -name 'screenlog.0_*'` ]]; then 
  find $DIR/$SRCDSDIR/$LOGDIR/ -type f -name 'screenlog.0*' -mtime $LOGTIME $LOGEXEC
fi

# PORTCHECK
if [[ `netstat -aunx |grep $PORT` ]]; then
  echo -e $ROT"Error:$FARBLOS Port $PORT ist schon belegt"
  exit
fi

cd $DIR/$SRCDSDIR
screen -$SCREENOPTIONS $SCREENNAME-running ./$BINARY -game $GAMEMOD -port $PORT +ip $IP +map $MAP +maxplayers $MAXPLAYERS $EXTRA 
echo -e $GELB"Server $SCREENNAME wurde gestartet."$FARBLOS


# --- EXTENSIONS --- #

# SOURCETV_EXTENSION
if [ -f "$DIR/extensions/sourcetv_extension.sh" ]; then
  chmod 755 $DIR/extensions/sourcetv_extension.sh
  $DIR/extensions/sourcetv_extension.sh start
fi

# ADVERT_EXTENSION
if [ -f "$DIR/extensions/advert_extension.sh" ]; then 
  chmod 775 $DIR/extensions/advert_extension.sh
  $DIR/extensions/advert_extension.sh start
fi

;;
# ---------------------------------------------------------------------------------------------



# STOP
# ---------------------------------------------------------------------------------------------
stop|2)
clear
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  screen -dr $SCREENNAME-running -X quit 
  echo -e $GELB"Server $SCREENNAME wurde gestoppt."$FARBLOS
else
  echo -e $ROT"Error:$FARBLOS Server $SCREENNAME ist bereits gestoppt."
fi

# --- EXTENSIONS --- #

# SOURCETV_EXTENSION
if [ -f "$DIR/extensions/sourcetv_extension.sh" ]; then 
  chmod 755 $DIR/extensions/sourcetv_extension.sh
  $DIR/extensions/sourcetv_extension.sh stop
fi

# ADVERT_EXTENSION
if [ -f "$DIR/extensions/advert_extension.sh" ]; then 
  chmod 755 $DIR/extensions/advert_extension.sh
  $DIR/extensions/advert_extension.sh stop
fi
;;
# ---------------------------------------------------------------------------------------------



# RESTART
# ---------------------------------------------------------------------------------------------
restart|3)
$0 stop
sleep 1
$0 start
;;
# ---------------------------------------------------------------------------------------------



# UPDATE
# ---------------------------------------------------------------------------------------------
update|install|4)
# PRECONFIGURE_IN
$0 preconfigure >/dev/null
# ----
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

# STOP
$0 stop
# ---
screen -dmS $SCREENNAME-update ./steam -command update -game "$UPDATEMOD" -dir . -verify_all -retry 
if [ "$UPDATE_SERVER_STAT" == "ON" ]; then
  clear; echo -e $GELB"Der Server $SCREENNAME wurde gestoppt, und das Update wurde im Screen $SCREENNAME-update gestartet."$FARBLOS
else
  clear; echo -e $GELB"Das Update wurde im Screen $SCREENNAME-update gestartet."$FARBLOS
fi
;;
# ---------------------------------------------------------------------------------------------



# STATUS
# ---------------------------------------------------------------------------------------------
status|5) 
# FALLS KEIN SCREENNAMEN GEFUNDEN WURDE --- TESTING ---
if [[ ! `screen -ls |grep $SCREENNAME-` ]]; then
  echo -e $GELB"Zurzeit werden auf diesem Server keine Aktivitaeten Ausgefuehrt."$FARBLOS
  exit
fi

if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  clear; echo -e $GELB"Server $SCREENNAME laeuft zurzeit."$FARBLOS
fi

if [ ! "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" == "DOWN" ]; then
  echo "---"
  echo "ServerName: `$QUAKESTAT -a2s $IP:$PORT |grep -v 'ADDRESS' |awk -F \"$GAMEMOD\" '{print $2}' |tr -d ' '`"
  echo "ServerAddress: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk '{print $1}'`"
  echo "Map: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $3}'`"
  echo "Players: `$QUAKESTAT -$QSTAT $IP:$PORT |grep -v 'ADDRESS' |awk  '{print $2}'`"
  echo "---"
fi

# Update
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  clear; echo -e $GELB"Server $SCREENNAME wird zurzeit geupdatet."$FARBLOS
fi

# Backup
if [[ `screen -ls |grep $SCREENNAME-backup` ]]; then
  clear; echo -e $GELB"Server $SCREENNAME wird zurzeit gebackuppt."$FARBLOS
fi

# --- EXTENSIONS --- #

# SOURCETV_EXTENSION
if [[ `screen -ls |grep $SCREENNAME-sourcetv` ]]; then
  echo -e $GELB"SourceTv  Daemon laeuft."$FARBLOS
fi

# ADVERT_EXTENSION
if [[ `screen -ls |grep $SCREENNAME-advert` ]]; then
  echo -e $GELB"Advert Daemon laeuft."$FARBLOS
fi
;;
# ---------------------------------------------------------------------------------------------



# WATCH
# ---------------------------------------------------------------------------------------------
watch|6)
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
;;
# ---------------------------------------------------------------------------------------------



# WATCHUPDATE
# ---------------------------------------------------------------------------------------------
watchupdate|7)
clear
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
;;
# ---------------------------------------------------------------------------------------------



# PING
# ---------------------------------------------------------------------------------------------
ping|8)
echo "Bitte kurz warten der Server wird angepingt."
sleep 0.5

if [ "`$QUAKESTAT -$QSTAT $IP:$PORT | grep -v ADDRESS | awk '{ print $2 }' | awk -F/ ' { print $1}'`" = "DOWN" ]; then
  echo "Der Server ist nicht anpingbar somit Down oder er startet/updated noch."
  else echo "Der Server ist anpingbar und laueft."
fi
;;
# ---------------------------------------------------------------------------------------------



# MAPLISTCREATE
# ---------------------------------------------------------------------------------------------
maplistcreate|9)
# FALLS MAPLIST VORHANDEN
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/maplist.txt" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD/
  mv maplist.txt "maplist.txt_`$DATE`"
fi

# FALLS MAPCYCLE VORHANDEN
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD
  mv mapcycle.txt "mapcycle.txt_`$DATE`"
fi

# MAPS SCHREIBEN
cd $DIR/$SRCDSDIR/$GAMEMOD
echo "// Maplist.txt created by GuGy.eu Server.sh $VERSION" > $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
echo "// Mapcycle.txt created by GuGy.eu Server.sh $VERSION" > $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt
echo "" >> $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
echo "" >> $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt
ls maps/ | grep '\.bsp$' | sed 's/\.bsp$//' | sort >> $DIR/$SRCDSDIR/$GAMEMOD/maplist.txt
ls maps/ | grep '\.bsp$' | sed 's/\.bsp$//' | sort >> $DIR/$SRCDSDIR/$GAMEMOD/mapcycle.txt

clear; echo -e $GELB"Mapliste und Mapcycle wurden erstellt, und die alten nach Datum gebackuppt."$FARBLOS
;;
# ---------------------------------------------------------------------------------------------



# LISTGAMES
# ---------------------------------------------------------------------------------------------
listgames|10)
clear
# CHECKEN OB HLDSUPDATETOOL VORHANDEN
if [ ! -f "steam" ]; then
  echo "Das Hldsupdatetool bzw Steam ist nicht vorhanden, und wird nun herruntergeladen."
  sleep 2
 
# HLDSUPDATETOOLBESORGUNG
  wget -q http://www.steampowered.com/download/hldsupdatetool.bin
  chmod 755 hldsupdatetool.bin
  echo "yes" | ./hldsupdatetool.bin
  ./steam -command update
fi

./steam -command list > games_available.txt

clear; echo "Die Spieleliste wurde von Steam bezogen, und in die Datei games_available.txt geschrieben."
echo "Diese wird dir nun angezeigt."
sleep 5
cat games_available.txt
;;
# ---------------------------------------------------------------------------------------------



# BACKUP
# ---------------------------------------------------------------------------------------------
backup|11)
if [[ `screen -ls |grep $SCREENNAME-running` ]]; then
  BACKUP_SERVER_STAT="ON"
  echo "Server $SCREENNAME laeuft noch und wird gestoppt."
  sleep 2
  screen -dr $SCREENNAME-running -X quit
fi

# Backup waehrend Update verhindern.
if [[ `screen -ls |grep $SCREENNAME-update` ]]; then
  echo -e $ROT"Error:$FARBLOS Update $SCREENNAME-update laeuft noch, Backup kann nicht gestartet werden."
 exit
fi

# Backup waehrend Backup verhindern.
if [[ `screen -ls |grep $SCREENNAME-backup` ]]; then
 echo -e $ROT"Error:$FARBLOS Backup $SCREENNAME-backup laeuft noch und Backup kann nicht gestartet werden."
 exit
fi

# BACKUPS NACH TMP SCHIEBEN FALLS VORHANDEN --- FIXME ---
if [[ `find $DIR/ -name '$SCREENNAME*.tar.gz'` ]]; then
  mv -f $SCREENNAME*.tar.gz $DIR/tmp
fi

screen -dmS $SCREENNAME-backup nice -n 19 tar cfvz $SCREENNAME.`$DATE`.tar.gz $BACKUP_FILES
if [ "$BACKUP_SERVER_STAT" == "ON" ]; then
  clear; echo -e $GELB"Der Server $SCREENNAME wurde gestoppt, und das Backup wurde im Screen $SCREENNAME-backup gestartet."$FARBLOS
else
  clear; echo -e $GELB"Das Backup wurde im Screen $SCREENNAME-backup gestartet."$FARBLOS
fi
  ;;
# ---------------------------------------------------------------------------------------------



# PRECONFIGURE
# ---------------------------------------------------------------------------------------------
preconfigure|12)
# Ordnercheck
if [ ! -d "$DIR/$SRCDSDIR/$GAMEMOD/cfg" ]; then
  echo "$DIR/$SRCDSDIR/$GAMEMOD/cfg existiert nicht."
  exit
fi

# Filecheck
# Preconf und Anlegung
if [ "$PRECONFDEL" == "1" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD/cfg
  mv $CFG1 "$CFG1-`$DATE`"
  mv $CFG2 "$CFG2-`$DATE`" 
fi

# Server.cfg
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/cfg/server.cfg" ]; then
  echo "Server.cfg schon vorhanden."
  exit
fi

# ----------
# Autoexec.cfg
if [ -f "$DIR/$SRCDSDIR/$GAMEMOD/cfg/autoexec.cfg" ]; then
  echo -e $GELB"autoexec.cfg schon vorhanden."$FARBLOS
  exit
fi

# Preconf und Anlegung
if [ "$PRECONFIGURE" == "1" ]; then
  cd $DIR/$SRCDSDIR/$GAMEMOD/cfg
  touch $CFG1 $CFG2
else
  echo -e $ROT"Error:$FARBLOS Variable Preconfigure ist nicht auf 1 gesetzt."
  exit
fi

echo "// Minimal Server/Autoexec\.cfg by GuGy.eu Server.sh $VERSION" > $CFG1
echo "// Minimal Server/Autoexec\.cfg by GuGy.eu Server.sh $VERSION" > $CFG2
echo "" >> $CFG1
echo "" >> $CFG1
echo "" >> $CFG2
echo "" >> $CFG2

# Config - Autoexec.cfg
echo "// Auszufuehrende Configs." >> $CFG1
echo "" >> $CFG1
echo "// Plugin Settings." >> $CFG1
echo "" >> $CFG1
echo "// Bunnyhop/Boost" >> $CFG1
echo 'sv_enableboost "1"' >> $CFG1
echo 'sv_enablebunnyhopping "1"' >> $CFG1
echo "" >> $CFG1
echo "" >> $CFG1


echo "// Befehle fuer den SourceTv." >> $CFG1
echo "" >> $CFG1
echo "// tv_record Name der Demo" >> $CFG1
echo "// tv_stoprecord" >> $CFG1
echo "// tv_stop" >> $CFG1
echo "" >> $CFG1
echo "// --- SourceTv ---" >> $CFG1
echo "" >> $CFG1
echo "// SourceTv An/Aus." >> $CFG1
echo 'tv_enable "0"' >> $CFG1
echo "" >> $CFG1
echo "// Port des TvServers." >> $CFG1
echo 'tv_port "27020"' >> $CFG1
echo "" >> $CFG1
echo "// Staendige Aufnahme zu jeder Zeit." >> $CFG1
echo 'tv_autorecord "0"' >> $CFG1
echo "" >> $CFG1
echo "// Maximale Spieleranzahl die auf den SourceTv verbinden kann." >> $CFG1
echo 'tv_maxclients "1"' >> $CFG1 >> $CFG1
echo "" >> $CFG1
echo "// Name des TvServers." >> $CFG1
echo 'tv_name "Mein SourceTv"' >> $CFG1
echo "" >> $CFG1
echo "// Passwort des SourceTv-Servers." >> $CFG1
echo 'tv_password "MeinPasswort"' >> $CFG1
echo "" >> $CFG1


# Config - Server.cfg
echo "// --- GENERELL ---" >> $CFG2
echo "" >> $CFG2



echo "// Name des Servers." >> $CFG2
echo 'hostname "MeinServerName"' >> $CFG2
echo "" >> $CFG2
echo "// Region des Servers 0=US Ostkueste, 1=US Westkueste, 2= Suedamerika, 3=Europa, 4=Asien, 5=Australien, 6=Mittlerer Osten, 7=Afrika und 255=Welt." >> $CFG2
echo 'sv_region "3"' >> $CFG2
echo "" >> $CFG2
echo "// Password fuer Verbindende Spieler." >> $CFG2
echo 'sv_password ""' >> $CFG2
echo "" >> $CFG2
echo "// 0/1=Verbietet den zugang fuer Spieler mit Custommodels oder anderen Waffenskins, Sounds u.s.w. 0=Erlaubt das Verwenden von" >> $CFG2
echo 'sv_consistency "1"' >> $CFG2
echo "" >> $CFG2
echo "// Einstellung der Zuschauerkamera fuer Tote Spieler. (0=Allen zuschauen + Freier Flug / 1=Nur Team zuschauen (Egoperspektive)" >> $CFG2
echo 'mp_forcecamera "1"' >> $CFG2
echo "" >> $CFG2
echo "// Loggt ale Aktionen auf dem Server in einem Logfile. (on=an off=aus) " >> $CFG2
echo 'log "on"' >> $CFG2

# Platzhalter

echo "" >> $CFG2
echo "// Password fuer den RCON Zugriff." >> $CFG2
echo 'rcon_password "UltraHighEndSicheresPasswort"' >> $CFG2
echo "" >> $CFG2
echo "// Erlauben der Taschenlampe." >> $CFG2
echo 'mp_flashlight "1"' >> $CFG2
echo "" >> $CFG2
echo "// Wie lange die Map laufen soll." >> $CFG2
echo 'mp_timelimit "15"' >> $CFG2
echo "" >> $CFG2
echo "// Teambeschuss." >> $CFG2
echo 'mp_friendlyfire "1"' >> $CFG2 
echo "" >> $CFG2
echo "// Sprachkommunikation auf dem Server erlauben." >> $CFG2
echo 'sv_voiceenable "1"' >> $CFG2
echo "" >> $CFG2
echo "// 1=Voice fuer Alle hoerbar. 0=Voice nur fuer das jeweilige Team hoerbar." >> $CFG2
echo 'sv_alltalk "1"' >> $CFG2
echo "" >> $CFG2
echo "// Downloadurl fuer Custom Content von einem Http Server." >> $CFG2
echo 'sv_downloadurl ""' >> $CFG2
echo "" >> $CFG2
echo "// Limitierung der Framerate." >> $CFG2
echo 'fps_max "101"' >> $CFG2
echo "" >> $CFG2
echo "" >> $CFG2


echo "// --- RATES ---" >> $CFG2
echo "" >> $CFG2 
echo "// Maximale Bandbreite." >> $CFG2
echo 'sv_maxrate "30000"' >> $CFG2
echo "" >> $CFG2 
echo "// Minimale Bandbreite." >> $CFG2
echo 'sv_minrate "7500"' >> $CFG2
echo "" >> $CFG2
echo "// Maximale Updaterate." >> $CFG2
echo 'sv_maxupdaterate "67"' >> $CFG2 
echo "" >> $CFG2
echo "// Minimale Updaterate." >> $CFG2
echo 'sv_minupdaterate "34"' >> $CFG2
echo "" >> $CFG2
echo "// Maximale Cmdrate." >> $CFG2
echo 'sv_maxcmdrate "67"' >> $CFG2
echo "" >> $CFG2
echo "// Minimale Cmdrate." >> $CFG2
echo 'sv_mincmdrate "34"' >> $CFG2
echo "" >> $CFG2


echo "// --- SONSTIGES ---" >> $CFG2
echo "" >> $CFG2
echo "// Erlaubt das Downloaden." >> $CFG2
echo 'sv_allowdownload "1"' >> $CFG2
echo "" >> $CFG2
echo "// Erlaubt das Uploaden." >> $CFG2
echo 'sv_allowupload "1"' >> $CFG2
echo "" >> $CFG2
echo "// Erstellt Logfiles." >> $CFG2
echo 'log "1"' >> $CFG2
echo "" >> $CFG2
echo "// Beschleunigung in Der Luft." >> $CFG2
echo 'sv_airaccelerate "150"' >> $CFG2
echo "" >> $CFG2
echo "// Beschleunigung im Wasser." >> $CFG2
echo 'sv_wateraccelerate "150"' >> $CFG2
echo "" >> $CFG2


echo "// Zusaetzliche Configs Ausfuehren." >> $CFG2
echo "exec autoexec.cfg" >> $CFG2
echo "exec banned_user.cfg" >> $CFG2
echo "exec banned_ip.cfg" >> $CFG2
echo "writeip" >> $CFG2
echo "writeid" >> $CFG2



clear
echo "$CFG1 und $CFG2 wurden in $SRCDSDIR/$GAMEMOD/cfg angelegt."

;;
# ---------------------------------------------------------------------------------------------



# UPDATEVERSION
# ---------------------------------------------------------------------------------------------
updateversion|13)
VERSIONCHECK_LOCAL="$VERSION" 
VERSIONCHECK_REMOTE="`wget -q -O- $VERSIONURL | fgrep  Version:`"
FEATURES="`wget -q -O- $FEATURESURL`"
CONFLOCK="`wget -q -O- $VERSIONURL | fgrep  LOCK=1`"


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

# CONFIGLOCK
if [[ $CONFLOCK ]]; then
 echo ""
 echo -e $GELB"Wichtig:$FARBLOS Das Update der Vorversion auf $VERSIONCHECK_REMOTE beinhaltet die Configdatei."
 echo "Sie sollten nun daher die Console unberueht lassen,"
 echo "und zB per FTP/SCP/SSH die Configdatei loeschen oder umbennen bevor sie das Update zustimmen."
fi

# FIXME
# Servercheck
# if [[ ! `wget -q -O- $UPDATEURL` ]]; then
# echo "Sorry der Contentserver ist zurzeit nicht erreichbar."
# exit
# fi

# --- 
echo "" 
echo -n "Wollen sie jetzt Updaten? yes/no: "
read updatequestion
if [ "$updatequestion" == "yes" ]; then
  wget -q $UPDATEURL
  
    # Archivcheck
    if [ ! -f "server.tar.gz" ]; then
      clear; echo -e $ROT"Error:$FARBLOS Das Updatearchiv konnte nicht gefunden werden. Abbruch"
      exit
    fi
	
# ---
cp $0  $0_`$DATE`
mv $0_* $DIR/tmp
  
if [ -f "server.conf" ]; then
 # Configmove if exist
 # FIXME
  tar xvf server.tar.gz --exclude server.conf --exclude make
  rm server.tar.gz
else
  tar xvf server.tar.gz --exclude make
  rm server.tar.gz
fi

  clear; echo -e $GELB"Update war erfolgreich"$FARBLOS
else 
  clear; echo -e $GELB"Update abgebrochen"$FARBLOS
  
fi
;;
# ---------------------------------------------------------------------------------------------



# VERSION
# ---------------------------------------------------------------------------------------------
version|14)
echo "Ihre Version:    $VERSION"
;;
# ---------------------------------------------------------------------------------------------



# ADDONISNTALL
# ---------------------------------------------------------------------------------------------
addoninstall|15)

# FALSCHEINGABE
if [ "$2" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Falscheingabe"
  echo "     Usage: addoninstall Addonname"
  exit
fi


# FALLS SCHON VORHANDEN
if [ -f "$DIR/$2.list" ]; then
  echo -ne $GELB"Das Addon $2 scheint schon installiert zu sein.$FARBLOS
  [- wollen sie es dennoch installieren? yes/no: "
  read addonquestion
  
  
    if [ ! "$addonquestion" == "yes" ]; then
      clear; echo -e $GELB"Das Addon $2  Wurde nicht installiert"$FARBLOS
      exit
   fi

   
fi


# DOWNLOAD DES ADDONS
echo -e $GELB"Einen Moment bitte."$FARBLOS

if [[ `wget -q -O- $ADDONURL/$2.tar.bz2` ]]; then
  clear; echo -e $GELB"Addon $2 wird herruntergeladen"$FARBLOS
  wget -q  $ADDONURL/$2.tar.bz2
  else echo -e $ROT"Addon $2.tar.bz2 ist nicht auf dem Masterserver vorhanden."$FARBLOS 
  exit
fi
# ---

# VERARBEITUNG DES ADDONS
if [ -f "$2.tar.bz2" ]; then
  tar xfvj $2.tar.bz2
  rm $2.tar.bz2
  clear; echo -e $GELB"Das Addon $2 wurde erfolgreich installiert."$FARBLOS
else
  echo -e $GELB"Das Addon $2.tar.bz2 existiert nicht!"$FARBLOS
  exit
fi
;;
# ---------------------------------------------------------------------------------------------



# ADDONREMOVE
# ---------------------------------------------------------------------------------------------
addonremove|16)

# FALSCHEINGABE
if [ "$2" == "" ]; then
  echo -e $ROT"Error:$FARBLOS Falscheingabe"
  echo "     Usage: addonremove Addonname"
  exit
fi


# PRUFEN UND DEINSTALLIEREN DES ADDONS 
if [ ! -f "$DIR/$2.list" ]; then
  echo -e $GELB"Die Addondatei $2.list existiert nicht!"$FARBLOS
  exit
fi

echo -e $GELB"Einen Moment bitte."$FARBLOS
sleep 1

# LOESCHFUNKTION
cat $DIR/$2.list |tr -d "\r" |while read list; do rm -Rf $list; done
rm $DIR/$2.list
# ---
clear; echo -e $GELB"Addon $2 wurde geloescht"$FARBLOS
;;
# ---------------------------------------------------------------------------------------------



# ADDONLIST
# ---------------------------------------------------------------------------------------------
addonlist|17)

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
;;
# ---------------------------------------------------------------------------------------------



# ADDONINSTALLED
# ---------------------------------------------------------------------------------------------
addons|addonlist_local|18)

# ADDONCHECK
if [[ `ls $DIR/*.list` ]]; then
  ls *.list | grep '\.list$' | sed 's/\.list$//' | sort > $DIR/addonslist.tmp
  else clear; echo -e $GELB"Es scheinen keine Addons installiert zu sein"$FARBLOS
  exit
fi


echo -e $GELB"Folgende Addons sind installiert"$FARBLOS
echo ""
echo "---"
echo "`cat $DIR/addonslist.tmp`"
echo "---"
rm $DIR/addonslist.tmp
;;
# ---------------------------------------------------------------------------------------------



# CLEANUP
# ---------------------------------------------------------------------------------------------
cleanup|19)
# WARNINGMESSAGE
echo -ne $GELB"Achtung$FARBLOS dieses Feature ist noch nicht ausgereift, wollen sie es dennoch nutzen? yes/no: "
  read CLEANUP_WARNING_MESSAGE
if [ ! "$CLEANUP_WARNING_MESSAGE" == "yes" ]; then
  clear; echo "Ihre Wahl, wir brechen ab." 
  exit
fi  
  

# ZTMP
# ---------------
echo "Loesche alte ztmp Dateien..."
# COUNT FILES
find $DIR/$SRCDSDIR/$GAMEMOD/ -name '*.ztmp' -mtime $LOGTIME | wc -l > $DIR/tmp/cleanup_ztmp_count.tmp
find $DIR/$SRCDSDIR/$GAMEMOD/ -name '*.ztmp' -mtime $LOGTIME $LOGEXEC

# AMOUNT OF REMOVED FILES
if [ -f "$DIR/tmp/cleanup_ztmp_count.tmp" ]; then
  CLEANUP_ZTMP_COUNT="`cat $DIR/tmp/cleanup_ztmp_count.tmp`"
  rm -f $DIR/tmp/cleanup_ztmp_count.tmp
else
  ZTMP_COUNT="Error beim lesen der Datei."
fi
sleep 2
# ---------------


# LOGS
# ---------------
echo "Loesche alte log Dateien..."
# COUNT FILES
find $DIR/$SRCDSDIR/$GAMEMOD/logs/ -type f -name '*.log' -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_log_count.tmp
find $DIR/$SRCDSDIR/$GAMEMOD/logs/ -type f -name '*.log' -mtime +$LOGTIME $LOGEXEC

# AMOUNT OF REMOVED FILES
if [ -f "$DIR/tmp/cleanup_log_count.tmp" ]; then
  CLEANUP_LOG_COUNT="`cat $DIR/tmp/cleanup_log_count.tmp`"
  rm -f $DIR/tmp/cleanup_log_count.tmp
else
  CLEANUP_LOG_COUNT="Error beim lesen der Datei."
fi
sleep 2
# ---------------


# DOWNLOADS
# ---------------
echo "Loesche alte Download Dateien..."
# COUNT FILES
find $DIR/$SRCDSDIR/$GAMEMOD/downloads/ -type f -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_downloads_count.tmp
find $DIR/$SRCDSDIR/$GAMEMOD/DownloadLists/ -type f -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_downloads2_count.tmp
# PUT IN DLL
echo $(( `cat $DIR/tmp/cleanup_downloads_count.tmp` + `cat $DIR/tmp/cleanup_downloads2_count.tmp`)) > $DIR/tmp/cleanup_downloads_count.tmp
rm -f $DIR/tmp/cleanup_downloads2_count.tmp

# REMOVE FILES
find $DIR/$SRCDSDIR/$GAMEMOD/downloads/ -type f -mtime +$LOGTIME $LOGEXEC
find $DIR/$SRCDSDIR/$GAMEMOD/DownloadLists/ -type f -mtime +$LOGTIME $LOGEXEC

# AMOUNT OF REMOVED FILES
if [ -f "$DIR/tmp/cleanup_downloads_count.tmp" ]; then
  CLEANUP_DOWNLOADS_COUNT="`cat $DIR/tmp/cleanup_downloads_count.tmp`"
  rm -f $DIR/tmp/cleanup_downloads_count.tmp
else
  CLEANUP_DOWNLOADS_COUNT="Error beim lesen der Datei."
fi
sleep 2
# ---------------


# SOURCETV
# ---------------
echo "Loesche alte Demo/SourceTv Dateien..."
# COUNT FILES
find $DIR/$SRCDSDIR/$GAMEMOD/ -type f -name '*.dem' -mtime +$LOGTIME |wc -l > $DIR/tmp/cleanup_demo_count.tmp
find $DIR/$SRCDSDIR/$GAMEMOD/logs/ -type f -name '*.dem' -mtime +$LOGTIME $LOGEXEC

# AMOUNT OF REMOVED FILES
if [ -f "$DIR/tmp/cleanup_demo_count.tmp" ]; then
  CLEANUP_DEMO_COUNT="`cat $DIR/tmp/cleanup_demo_count.tmp`"
  rm -f $DIR/tmp/cleanup_demo_count.tmp
else
  CLEANUP_DEMO_COUNT="Error beim lesen der Datei."
fi
sleep 2
# ---------------

clear; echo -e $GELB"Server wurde aufgeraeumt."$FARBLOS
echo "Es wurden: '$CLEANUP_ZTMP_COUNT' Ztmp Dateien, '$CLEANUP_LOG_COUNT' Log Dateien, '$CLEANUP_DEMO_COUNT' Demo/SourceTv Dateien, und '$CLEANUP_DOWNLOADS_COUNT' Download/s entfernt."
;;
# ---------------------------------------------------------------------------------------------



# CRONJOB
# ---------------------------------------------------------------------------------------------
cronjob|crontab|cron|20)
clear
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

# IF CRON ALREADY EXIST --- FIXME ---
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
;;
# ---------------------------------------------------------------------------------------------



# HELP
# ---------------------------------------------------------------------------------------------
h|help|-h|--help|21)
clear
echo "Ausfuehrbare Befehle"
echo "Usage: $0 {Code/Befehl}"
echo "Code | Befehl | Beschreibung"
echo "____________________________"
echo ""
echo "1)  start                     - Startet den Gameserver."
echo "2)  stop                      - Stoppt den Gameserver."
echo "3)  restart                   - Restartet den Gameserver."
echo "4)  update|install            - Updatet/Installiert den Gameserver. | Gleich wie Update."
echo "5)  status                    - Zeigt den Status des Gameservers."
echo "6)  watch                     - Oeffnet die Screensession des Gameservers."
echo "7)  watchupdate               - Oeffnet die Screensession des Updaters."
echo "8)  ping                      - Pingt den Server an und checkt ob er online ist."
echo "9)  maplistcreate             - Erstellt eine maplist.txt aller .bsp Dateien in standartgemaess srcdsdir/moddir/maps."
echo "10) listgames                 - Listet alle Spiele die ueber Steam bezogen werden koennen und schreibt sie in games_avaible.txt"
echo "11) backup                    - Backuppt den Gesamten Gameserver in das Hauptverzeichnis mit Angabe des Datumsformates (siehe unten)."
echo "12) preconfigure              - Es wird eine Minimale Server/Autoexec\.cfg in standartgemaess srcdsdir/moddir/cfg erstellt."
echo "13) updateversion             - Prueft die Locale Scriptversion und vergleicht diese mit dem Updateserver"
echo "                             [- falls eine neue Version vorhanden ist kann sie nach zustimmung geupdatet werden."
echo "                             [- Die alte Version geht dabei nicht verloren."
echo "14) version                   - Zeigt lediglich die Version an."
echo "15) addoninstall              - Laed ein Addon Vom dem in der Config eingetragenen Masterserver und Installiert es."
echo "16) addonremove               - Loescht ein Addon das Vom Masterserver bezogen werden kann."
echo "17) addonlist                 - Listet alle Addons auf die ueber den Installer bezogen werden koennen"
echo "18) addons|addonlist_local    - Listet alle Addons auf die ueber den Installer installiert wurden"
echo "19) cleanup                   - Feature to come..."
echo "20) cronjob|crontab|cron      - Erstellt einen Taeglichen Cronjob [BETA]."
echo ""
echo ""
echo "21) help|h                    - Zeigt diese Hilfe an"
;;
# ---------------------------------------------------------------------------------------------



*)
echo "Usage: $0 {start|stop|restart|update|status|watch|watchupdate|ping|maplistcreate|listgames|backup|help}"
;;

esac
exit 



