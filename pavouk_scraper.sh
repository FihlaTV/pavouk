#!/bin/bash

#Input File created with ScriptTOGetListOfFiles.html
input="Movies2.csv"


function main {
	while IFS= read -r var
	do
		baseURL="https://ia800300.us.archive.org/1/items/$var/"
		#######Download metadata#####
		wget -nv -nc $baseURL$var"_files.xml"
		wget -nv -nc $baseURL$var"_meta.xml"
		
		
		######Download and re-encode movie#####
		videoFileName=`cat $var"_files.xml" |grep source=\"original\"| grep -v "srt" |cut -d'"' -f2`
		wget -nv -nc $baseURL$videoFileName
		ffmpeg -i $videoFileName -c:v libx264 -crf 22 -c:a aac -strict experimental -movflags faststart "${videoFileName%.*}".mp4
		python pavouk_publish.py $var
		
		# for testing; prevents multiple files being published
		exit 0
	
	done < "$input"
	

}
main 
