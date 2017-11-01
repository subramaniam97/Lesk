import xml.etree.ElementTree as ET
tree = ET.parse("/home/subbu/Desktop/MP/pylesk/senseval/Sval2.xml/dataWithoutHead.xml")
tree1 = ET.parse("/home/subbu/Desktop/MP/pylesk/senseval/Sval2.xml/data.xml")
root = tree.getroot()
root1 = tree1.getroot()


print(len(root)) 
