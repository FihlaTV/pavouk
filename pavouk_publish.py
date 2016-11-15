import xml.etree.ElementTree as ET
import sys


def publish (movie):
	title= parseXML(movie +"_meta.xml", "title")
	author= parseXML(movie +"_meta.xml", "creator")
	description= parseXML(movie +"_meta.xml", "description")
		

##Gets The contents of the given tag in the XML file
def parseXML (file,tag):
	tree = ET.parse(file)
	root = tree.getroot()
	for child in root:
		if child.tag == tag:
			return child.text

publish(sys.argv[1])
