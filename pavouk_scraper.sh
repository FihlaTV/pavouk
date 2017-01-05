#!/bin/bash

#Input File created with ScriptTOGetListOfFiles.html
input="Movies2.csv"
workingDir="/mnt/volume-nyc1-02"
currentDir=`pwd`

#workingDir=$currentDir

echo "" > $currentDir/debugging.log

#######Download metadata#####
function downloadMetadata {
	baseURL="https://ia800300.us.archive.org/1/items/$var/"	
	wget -nv -nc $baseURL$var"_files.xml"
	wget -nv -nc $baseURL$var"_meta.xml"
}

function parseMetadata {
	########################
	#####Optional Thumbnail
	#thumbnailPath="$workingDir/"`cat $var"_files.xml" |grep -Pzo -m1 "(?s)<file [^>]*>.\s*<format>Thumbnail" |head -2|tail -n1 |cut -d'"' -f2`
	#wget -nv -nc $baseURL$thumbnailFileName
	##################
	
	title=$(parseXML "$workingDir/$var"_meta.xml title)
	adjustedTitle=$(echo ${title//\'/''}| awk '{print tolower($0)}' | tr -s " " |xargs)
	propperTitle=$(echo ${adjustedTitle//[^a-zA-Z0-9]/-}| awk '{print tolower($0)}')
	
	author=$(parseXML "$workingDir/$var"_meta.xml creator director)
			
	description=$(parseXML "$workingDir/$var"_meta.xml description)
	description=${description//\"/\'}
	
	echo "propperTitle: $propperTitle" >>$currentDir/debugging.log
	echo "author: $author" >>$currentDir/debugging.log
	echo "description: $description" >>$currentDir/debugging.log
	
	
	license_url=$(parseXML "$workingDir/$var"_meta.xml licenseurl license)
}
	######Download and re-encode movie#####
function convertVideoToMP4 {

	videoFileName=`cat $workingDir/$var"_files.xml" |grep \<original\>|tail -1 |cut -d"<" -f2|cut -d">" -f2`
	#`cat $var"_files.xml" |grep source=\"original\" |cut -d'"' -f2 |xargs`
	
	filePath="$workingDir/$propperTitle.mp4"
	
	#If file does not exist
	if [ ! -s "$filePath" ]; then 
		echo "Getting video from $baseURL$videoFileName"
		wget -nv -nc $baseURL$videoFileName
		echo "Re-encoding $videoFileName ->  $filePath"
		ffmpeg -hide_banner -loglevel panic -y -i $videoFileName -c:v libx264 -crf 22 -c:a aac -strict experimental -movflags faststart $filePath  &> /dev/null
	else
		echo "file is already in correct format"
	fi

	if [ ! -s "$filePath" ]; then 
		echo "file still does not exist: $filePath"
		echo "path gotten from $baseURL$videoFileName"
	fi	
}

function publish {
	echo "Publishing"
	 #,"thumbnail":"'"$thumbnailFileName"'"
	txid=$(lbrynet-cli publish '{"name":"'"$propperTitle"'","file_path":"'"$filePath"'","bid":0.000001,"metadata":{"ver": "0.0.3", "title": "'"$title"'", "author":"'"$author"'", "description": "'"$description"'", "nsfw":false,"language":"en","license":"'"$license_url"'"}}')
	echo "txid=$txid"
	if [ "$txid" != "null" ] && [ "$txid" != "" ]; then
		echo "published $propperTitle"
	else
		echo "error publishing $propperTitle"
		echo `cat ~/.lbrynet/lbrynet*log | grep $var |tail -n3`
	fi
}

function cleanUp {
	if [ "$videoFileName" != "$propperTitle.mp4" ] && [ -s "$videoFileName" ] ; then 
		echo "deleting $videoFileName"; 
		rm $videoFileName; 
	fi
}

function main {
	
	cd $workingDir
	movies=()
	while read -r var;	do
		movies+=($var)
	done
	for var in "${movies[@]}";do
		echo "Downloading $var"
		downloadMetadata
		parseMetadata
		convertVideoToMP4
		publish
		cleanUp

		########For testing purposes; 
		if [ -a "$currentDir/die" ] ; then 
			echo "kill signal received; exiting"
			exit 0
		else echo "$currentDir/die does not exists"
		fi
		########
	done
	echo "finished"
}

function parseXML {
	name=$1
	shift
	python3 $currentDir/parseXML.py "$name" ${@}
}

cat movies.txt |main
