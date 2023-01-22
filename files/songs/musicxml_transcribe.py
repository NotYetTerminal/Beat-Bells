import xml.etree.ElementTree as ET

file: str = 'songs/Mantis Lords'
tree = ET.parse(file + '.musicxml')
music_data = tree.getroot()[0]

if music_data.tag != 'part':
    for element in tree.getroot():
        print(element.tag, element.attrib)
    quit()

treble_line: list = []
bass_line: list = []
treble_bar_list: list = []
bass_bar_list: list = []
previous_note_x_data: str = ''
previous_beat_duration: int = 0
note_data_dict: dict = {'step': '', # capital letter
                        'octave': '', # int
                        'alter': '0', # -2 <-> 2
                        'duration': '', # number of beats int
                        'beat_count': ''} # beat number int

beat_count: int = 0
for bar in music_data:
    treble_bar_list = []
    bass_bar_list = []
    for item in bar:
        if item.tag == 'note':
            note_data_dict = {'step': '',
                              'octave': '',
                              'alter': '0',
                              'duration': '',
                              'beat_count': ''}
            for data in item:
                if data.tag == 'pitch':
                    for data2 in data:
                        note_data_dict[data2.tag] = data2.text
                if data.tag == 'duration':
                    note_data_dict[data.tag] = data.text
                
                if data.tag == 'staff':
                    if len(item.attrib.keys()) != 0 and item.attrib['default-x'] != previous_note_x_data and (previous_note_x_data == '' or abs(float(item.attrib['default-x']) - float(previous_note_x_data)) > 12):
                        beat_count += previous_beat_duration
                        previous_beat_duration = int(note_data_dict['duration'])
                        previous_note_x_data = item.attrib['default-x']
                    elif len(item.attrib.keys()) == 0:
                        beat_count += previous_beat_duration
                        previous_beat_duration = int(note_data_dict['duration'])
                        previous_note_x_data = ''

                    note_data_dict['beat_count'] = beat_count

                    if data.text == '1':
                        treble_bar_list.append(note_data_dict)
                    elif data.text == '2':
                        bass_bar_list.append(note_data_dict)
                    else:
                        print('Error')
                        print(data.text)
                        input()
        
        elif item.tag == 'backup':
            for data in item:
                if data.tag == 'duration':
                    beat_count -= int(data.text)
    
    treble_line.append(treble_bar_list)
    bass_line.append(bass_bar_list)
    # for thing in treble_line[0]:
    #     print(thing)
    # print()
    # for thing in bass_line[0]:
    #     print(thing)
    #break


def convert_duration_amount(dur_in: str) -> str:
    dur_in = int(dur_in)
    if dur_in > 16 or dur_in < 1:
        print('Time error')
        print(dur_in)
        input()
    
    return chr(dur_in + 64)

# music note in txt is made up as following
# first character is a letter from A to P representing the number of quater beats to play, 1 - 16
# second is the note frequency number from 0 to 8
# third is the note frequency character from a to g
# lastly is whether it is a neutral or sharp, n/s
def export_music_data(file_name: str, music_data: list):
    exported_music_data: list = []
    note_string: str = ''
    previous_beat_count: int = -1

    for bar in music_data:
        for note in bar:
            if note['step'] != '':
                note_string = convert_duration_amount(note['duration']) + str(note['octave']) + note['step'].lower()
                if note['alter'] == '1':
                    note_string += 's'
                elif note['alter'] == '-1':
                    note['step'] = chr(ord(note['step']) - 1)
                    if note['step'] == '@':
                        note['step'] = 'G'
                    note_string = convert_duration_amount(note['duration']) + str(note['octave']) + note['step'].lower()
                    if note['step'] != 'B' and note['step'] != 'E':
                        note_string += 's'
                    else:
                        note_string += 'n'
                elif note['alter'] != '0':
                    print('Error')
                    print(note)
                    input()
                else:
                    note_string += 'n'
                if previous_beat_count == note['beat_count']:
                    exported_music_data[-1] += note_string
                else:
                    for _ in range(note['beat_count'] - previous_beat_count - 1):
                        exported_music_data.append('0')
                    
                    exported_music_data.append(note_string)
                    previous_beat_count = note['beat_count']

    for _ in range(16 - (len(exported_music_data) % 16)):
        exported_music_data.append('0')

    with open(file_name + '.txt', 'w') as f:
        end_index: int = 4
        for start_index in range(0, len(exported_music_data), 4):
            f.write(','.join(exported_music_data[start_index:end_index]) + ',\n')
            end_index += 4
        f.write('0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n')
        f.write('0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n0,0,0,0')
        

export_music_data(file + ' T', treble_line)
export_music_data(file + ' B', bass_line)

