#!/bin/bash

#Input File created with ScriptToGetListOfFiles.html
input="movies.txt"
workingDir="/mnt/volume-nyc1-02"
currentDir=$(pwd)

workingDir="$currentDir"

echo "" > "$currentDir/debugging.log"

#######Download metadata#####
function downloadMetadata {
	baseURL="https://ia800300.us.archive.org/1/items/$var/"	
	wget -nv -nc "$baseURL$var""_files.xml"
	wget -nv -nc "$baseURL$var""_meta.xml"
	thumbnailFileName="$var"
	wget -O "$thumbnailFileName" -nv -nc "https://archive.org/services/img/$var";
}

function parseMetadata {
		
	title=$(parseXML "$workingDir/$var"_meta.xml title)
	
	propperTitle=$(echo "$title"| awk '{print tolower($0)}')
	#remove apostrophes 	
	propperTitle=${propperTitle//\'/''}
	#remove spaces if less than n characters
	if [ ${#propperTitle} -lt 20 ];then
		propperTitle=$(echo "$adjustedTitle" | tr -s " " |xargs)
	fi 
	#remove non-alpha numeric characters	
	propperTitle=${propperTitle//[^a-zA-Z0-9]/-}
	
	author=$(parseXML "$workingDir/$var"_meta.xml creator director)
			
	description=$(parseXML "$workingDir/$var"_meta.xml description)
	description=${description//\"/\'}
	
	{ echo "propperTitle: $propperTitle"; echo "author: $author";echo "description: $description";  }  >> "$currentDir/debugging.log"
	
	license_url=$(parseXML "$workingDir/$var"_meta.xml licenseurl license)
}
	######Download and re-encode movie#####
function convertVideoToMP4 {

	videoFileName=$(grep \<original\> "$workingDir/$var""_files.xml" |tail -1 |cut -d"<" -f2|cut -d">" -f2)
	#`cat $var"_files.xml" |grep source=\"original\" |cut -d'"' -f2 |xargs`
	
	filePath="$workingDir/$propperTitle.mp4"
	
	#If file does not exist
	#if [ ! -s "$filePath" ]; then 
		echo "Getting video from $baseURL$videoFileName"
		wget -nv -nc "$baseURL$videoFileName"
		echo "Re-encoding $videoFileName ->  $filePath"
		ffmpeg -hide_banner -loglevel panic -y -i "$videoFileName" -c:v libx264 -crf 22 -c:a aac -strict experimental -movflags -g [same-number-as-framerate] faststart "$filePath"  &> /dev/null
	#else
	#	echo "file is already in correct format"
	#fi

	if [ ! -s "$filePath" ]; then 
		echo "file still does not exist: $filePath"
		echo "path gotten from $baseURL$videoFileName"
	fi	
}

function publish {
	echo "Publishing"
	txid=$(/opt/venvs/lbrynet/bin/lbrynet-cli publish '{"name":"'"$propperTitle"'","file_path":"'"$filePath"'","bid":0.000001,"metadata":{"ver": "0.0.3", "title": "'"$title"'", "author":"'"$author"'", "description": "'"$description"'", "nsfw":false,"language":"en","license":"'"$license_url"'","thumbnail":"'"$thumbnailFileName"'"}}')
	echo "txid=$txid"
	if [ "$txid" != "null" ] && [ "$txid" != "" ]; then
		echo "published $propperTitle"
	else
		echo "error publishing $propperTitle"
		grep "$var" ~/.lbrynet/lbrynet*log |tail -n3
	fi
}

function cleanUp {
	if [ "$videoFileName" != "$propperTitle.mp4" ] && [ -s "$videoFileName" ] ; then 
		echo "deleting $videoFileName"; 
		rm "$videoFileName"; 
	fi
}

function main {
	
	cd "$workingDir" || exit
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
	python3 "$currentDir/parseXML.py" "$name" "${@}"
}

main < "$input"
