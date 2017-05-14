#!/bin/bash

#download path theme (generated with overpass API)
downloadpaththematic="http://overpass-api.de/api/interpreter?data=[out:xml];area(3600062422)-%3E.a;(node[%22amenity%22=%22pub%22][%22smoking%22][%22smoking%22!~%22no|outside%22](area.a);way[%22amenity%22=%22pub%22][%22smoking%22][%22smoking%22!~%22no|outside%22](area.a);relation[%22amenity%22=%22pub%22][%22smoking%22][%22smoking%22!~%22no|outside%22](area.a);node[%22amenity%22=%22bar%22][%22smoking%22][%22smoking%22!~%22no|outside%22](area.a);way[%22amenity%22=%22bar%22][%22smoking%22][%22smoking%22!~%22no|outside%22](area.a);relation[%22amenity%22=%22bar%22][%22smoking%22][%22smoking%22!~%22no|outside%22](area.a););out%20body;%3E;out%20skel%20qt;"

# db name theme
dbnamethematic="raucherkneipen.sqlite"
# OSM file name theme
osmfilenamethematic="raucherkneipen.osm"
# lock name
lockdir="updateosmdb.lock"
# style file
stylef="style.sql"
# logfile
logfile="log.txt"

function quitjob {
	
	echo "Problem during update. Cleanup" >> $logfile	
	if [ -f "$osmfilenamethematic" ]; then rm "$osmfilenamethematic"  
	fi
	if [ -f "$stylef" ]; then rm "$stylef" 
	fi
	if [ -f "unkreativer_db_name.sqlite" ]; then rm "unkreativer_db_name.sqlite" 
	fi 
	rm -rf "$lockdir"
	echo "+++++++ ENDE ++++++++" >> $logfile
	exit 1
}

echo "+++++++ Start ++++++++" >> $logfile
echo Time: `date` >> $logfile
if [ -d "$lockdir" ] ; then
	echo "old process still running. Stop" >> $logfile 
	exit 1
fi

mkdir "$lockdir"
echo "lockdir gesetzt" >> $logfile

echo "Download thematic overlay from Geofabrik" >> $logfile
wget -q "$downloadpaththematic" -O "$osmfilenamethematic"
if [ $? -ne 0 ] || [ ! -f "$osmfilenamethematic" ] ; then quitjob	
fi
echo "Download thematic overlay successfull" >> $logfile

echo "load Style" >> $logfile
sqlite3 "$dbnamethematic" ".dump 'layer_styles'" >"$stylef"
if [ ! -f "$stylef" ]; then quitjob
fi

echo "creating database theme" >> $logfile
ogr2ogr --config OSM_USE_CUSTOM_INDEXING NO --config OSM_CONFIG_FILE config/osmconf.ini -f "SQLite" -dsco SPATIALITE=YES unkreativer_db_name.sqlite "$osmfilenamethematic"
if [ $? -ne 0 ] || [ ! -f "unkreativer_db_name.sqlite" ]; then quitjob 
fi

echo "apply Style" >> $logfile
style=$(<$stylef)
sqlite3 unkreativer_db_name.sqlite "$style"
if [ $? -ne 0 ]; then quitjob
fi 
echo "delete downloaded file" >> $logfile
rm "$osmfilenamethematic"

echo "delete old DB" >> $logfile
rm "$dbnamethematic"

rm "$stylef"
mv "unkreativer_db_name.sqlite" "$dbnamethematic"

echo "delete lockfile" >> $logfile
rm -rf "$lockdir"
echo "+++++++ ENDE ++++++++" >> $logfile
