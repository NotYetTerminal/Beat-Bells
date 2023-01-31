import xml.etree.ElementTree as ET
import math

file: str = 'songs/Running_in_the_90s'
tree = ET.parse(file + '.musicxml')
music_data = ''

for element in tree.getroot():
    if element.tag == 'part':
        music_data = element
        break
    print(element.tag, element.attrib)

if music_data == '':
    print('Not Found')
    quit()

treble_line: list = []
bass_line: list = []
previous_note_x_data: str = ''
previous_beat_duration: int = 0
note_data_dict: dict = {'step': '', # capital letter
                        'octave': '', # int
                        'alter': '0', # -2 <-> 2
                        'type': 0, # number of beats
                        'default-x': 0,
                        'staff': '0'} # beat number int

nothing_note_data_dict: dict = {'step': '',
                                'octave': '',
                                'alter': '0',
                                'duration': 0,
                                'default-x': -1,
                                'staff': '0'}

lowest_duration: float = 64.0
durations: list = []
types: list = []
full_music_data: list = []

# duration_dict: dict = {'2': 1,
#                        '3': 2,
#                        '4': 3,
#                        '6': 4,
#                        '12': 8,
#                        '24': 16}
                       
# duration_dict: dict = {'1': 1,
#                        '2': 2,
#                        '4': 4,
#                        '6': 6,
#                        '8': 8,
#                        '12': 12,
#                        '16': 16}

def sum_durations(bar_container: list) -> int:
    total_duration: int = 0
    used_x: list = []
    for note_thing in bar_container:
        if note_thing['default-x'] not in used_x:
            total_duration += note_thing['duration']
            used_x.append(note_thing['default-x'])
    return total_duration


def reduce_highest(bar_container: list):
    highest_duration: int = 0
    highest_duration_index: int = 0
    for note_thing_index in range(len(bar_container)):
        if bar_container[note_thing_index]['duration'] > highest_duration:
            highest_duration = bar_container[note_thing_index]['duration']
            highest_duration_index = note_thing_index
    
    bar_container[highest_duration_index]['duration'] -= 1


note_duration: int = 0
divisor: float = 1.0
treble_bar_container: list = []
bass_bar_container: list = []

for bar1 in music_data:
    treble_bar_container = []
    bass_bar_container = []
    for item in bar1:
        if item.tag == 'note':
            note_data_dict = {'step': 'Z',
                              'octave': '',
                              'alter': '0',
                              'duration': 0,
                              'default-x': -1,
                              'staff': '0'}
            if 'default-x' in item.attrib:
                note_data_dict['default-x'] = item.attrib['default-x']
            
            for data in item:
                if data.tag == 'pitch':
                    for data2 in data:
                        note_data_dict[data2.tag] = data2.text
                elif data.tag == 'duration':
                    note_duration = math.ceil(float(data.text) / divisor)

                    #if data.text in duration_dict.keys():
                    note_data_dict[data.tag] = note_duration#duration_dict[data.text]
                    # else:
                    #     print('Key Error')
                    #     print(data.text)

                    # durations stuff
                    if note_duration < lowest_duration:
                        lowest_duration = note_duration
                        #print(item[1].text)
                        #print(item[3].text)
                    for data2 in item:
                        if data2.tag == 'type':
                            types.append(data2.text)
                            durations.append(float(data.text) / divisor)
                            break
                elif data.tag == 'staff':
                    note_data_dict['staff'] = data.text
                # elif data.tag == 'notations' and len(data[0].attrib) != 0 and data[0].attrib['type'] == 'stop' and note_data_dict['duration'] != 1:
                #     #print(note_data_dict)
                #     note_data_dict['step'] = 'Z'
                #     note_data_dict['octave'] = '-1'
                #     note_data_dict['alter'] = '0'
            
            if note_data_dict['duration'] != 0:
                if note_data_dict['staff'] == '1':
                    treble_bar_container.append(note_data_dict)
                    
                if note_data_dict['staff'] == '2':
                    bass_bar_container.append(note_data_dict)


    while sum_durations(treble_bar_container) > 16:
        reduce_highest(treble_bar_container)
    
    if sum_durations(treble_bar_container) < 16:
        print('Bar length error')
        input()

    while sum_durations(bass_bar_container) > 16:
        reduce_highest(bass_bar_container)
    
    if sum_durations(bass_bar_container) < 16:
        print('Bar length error')
        input()
    
    full_music_data.extend(treble_bar_container)
    full_music_data.extend(bass_bar_container)
    full_music_data.append(nothing_note_data_dict)


full_music_data.append(nothing_note_data_dict)

temp_dict: dict = {}
print(len(durations))
print(len(types))
print(len(full_music_data))
for index in range(len(types)):
    if types[index] not in temp_dict:
        temp_dict[types[index]] = []
    if durations[index] not in temp_dict[types[index]]:
        temp_dict[types[index]].append(durations[index])

print(lowest_duration)
print(temp_dict)
input('Continue?')

treble_note_conversion_dict: dict = {'A': 'A',
                                     'B': 'B',
                                     'C': 'C',
                                     'D': 'Q',
                                     'E': 'R',
                                     'F': 'S',
                                     'G': 'G',
                                     'Z': 'Z'}

bass_note_conversion_dict: dict = {'A': 'D',
                                   'B': 'E',
                                   'C': 'F',
                                   'D': 'T',
                                   'E': 'U',
                                   'F': 'V',
                                   'G': 'G',
                                   'Z': 'Z'}

for note_index in range(len(full_music_data) - 1):
    note = full_music_data[note_index]
    if note['staff'] == '1':
        if full_music_data[note_index + 1]['staff'] == '1' and abs(float(full_music_data[note_index + 1]['default-x']) - float(note['default-x'])) <= 15:
            note['default-x'] = 0
        note['step'] = treble_note_conversion_dict[note['step']]
        treble_line.append(note)
    elif note['staff'] == '2':
        if full_music_data[note_index + 1]['staff'] == '2' and abs(float(full_music_data[note_index + 1]['default-x']) - float(note['default-x'])) <= 15:
            note['default-x'] = 0
        note['step'] = bass_note_conversion_dict[note['step']]
        bass_line.append(note)


def convert_duration_amount(dur_in: int) -> str:
    return chr(dur_in + 64)

# music note in txt is made up as following
# first character is a letter from A to P representing the number of quater beats to play, 1 - 16
# second is the note frequency number from 0 to 8
# third is the note frequency character from a to g
# lastly is whether it is a neutral or sharp, n/s
def export_music_data(file_name: str, in_music_data: list):
    exported_music_data: list = []
    note_string: str = ''
    index: int = 0

    for note in in_music_data:
        #if index < 50:
        #    print(note, index)
        note_string = convert_duration_amount(note['duration']) + note['octave'] + note['step'].lower()
        if note['alter'] == '1':
            note_string += 's'
        elif note['alter'] == '-1':
            note['step'] = chr(ord(note['step']) - 1)
            if note['step'] == '@':
                note['step'] = 'G'
            if note['step'] == 'B':
                note['octave'] = str(int(note['octave']) - 1)
            note_string = convert_duration_amount(note['duration']) + note['octave'] + note['step'].lower()
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
        
        #if index < 50:
        #    print(note_string)
        if note['step'] != '':
            if note['step'] != 'Z':
                if note['default-x'] == 0:
                    if len(exported_music_data) == 0 or in_music_data[index - 1]['default-x'] != 0:
                        exported_music_data.append(note_string)
                    else:
                        exported_music_data[-1] += note_string
                else:
                    if len(exported_music_data) == 0 or exported_music_data[-1] == '0' or in_music_data[index - 1]['default-x'] != 0:
                        exported_music_data.append(note_string)
                    else:
                        exported_music_data[-1] += note_string
                    for _ in range(note['duration'] - 1):
                        exported_music_data.append('0')
            else:
                if note['octave'] == '-1':
                    note['duration'] -= 1
                for _ in range(note['duration']):
                    exported_music_data.append('0')
        index += 1

    if len(exported_music_data) % 16 != 0:
        for _ in range(16 - (len(exported_music_data) % 16)):
            exported_music_data.append('0')

    print(file_name)
    with open(input('New name: ') + '.txt', 'w') as f:
        end_index: int = 4
        for start_index in range(0, len(exported_music_data), 4):
            f.write(','.join(exported_music_data[start_index:end_index]) + ',\n')
        
            #if end_index % 16 == 0:
            #    f.write('\n')
            end_index += 4
            
        f.write('0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n')
        f.write('0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n0,0,0,0')


export_music_data(file + ' T', treble_line)
export_music_data(file + ' B', bass_line)

