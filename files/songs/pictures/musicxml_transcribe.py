import xml.etree.ElementTree as ET


tree = ET.parse(input('File name: ') + '.musicxml')
root = tree.getroot()

all_bars = root[3]

print(all_bars[0].tag, all_bars[0].attrib)
all_bars = all_bars[1:]

print(len(all_bars))

for bar in all_bars:
    print(bar.tag, bar.attrib)
