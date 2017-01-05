import xml.etree.ElementTree as ET
import sys

def parseXML (file,tags):
	#checks tags in order
	for tag in tags:
		tree = ET.parse(file)
		root = tree.getroot()
		for child in root:
			if child.tag == tag and child.text!=None:
				if "Note:" in child.text:
					return child.text[:child.text.index("Note:")] 
				else: return child.text.splitlines()[0]
	return ""


print (parseXML(sys.argv[1],sys.argv[2:]))