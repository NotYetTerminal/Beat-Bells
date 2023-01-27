import xml.etree.ElementTree as ET
import math

file: str = 'songs/Spring_(La_primavera)(only_Allegro!)_-_Antonio_Vivaldi'
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
treble_bar_list: list = []
bass_bar_list: list = []
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

note_duration: int = 0
multiplier: float = 4

for bar1 in music_data:
    for item in bar1:
        if item.tag == 'note':
            note_data_dict = {'step': 'R',
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
                    note_duration = math.ceil(float(data.text) / (480.0 / multiplier))

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
                            durations.append(float(data.text) / (480.0 / multiplier))
                            break
                elif data.tag == 'staff':
                    note_data_dict['staff'] = data.text
                elif data.tag == 'notations' and len(data[0].attrib) != 0 and data[0].attrib['type'] == 'stop' and note_data_dict['duration'] != 1:
                    #print(note_data_dict)
                    note_data_dict['step'] = 'R'
                    note_data_dict['octave'] = '-1'
                    note_data_dict['alter'] = '0'
            
            if note_data_dict['duration'] != 0:
                full_music_data.append(note_data_dict)

        
        # elif item.tag == 'backup':
        #     for data in item:
        #         if data.tag == 'duration':
        #             full_music_data.append(int(data.text))
    
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

treble_index: int = 0
beat_count: int = 0
for note_index in range(len(full_music_data) - 1):
    note = full_music_data[note_index]
    if note['staff'] == '1':
        if full_music_data[note_index + 1]['staff'] == '1' and abs(float(full_music_data[note_index + 1]['default-x']) - float(note['default-x'])) <= 15:
            note['default-x'] = 0
        treble_line.append(note)
        treble_index += 1
    elif note['staff'] == '2':
        if full_music_data[note_index + 1]['staff'] == '2' and abs(float(full_music_data[note_index + 1]['default-x']) - float(note['default-x'])) <= 15:
            note['default-x'] = 0
        bass_line.append(note)
#quit()
    #     if item.tag == 'note':
    #         note_data_dict = {'step': '',
    #                           'octave': '',
    #                           'alter': '0',
    #                           'duration': 0,
    #                           'beat_count': 0}
    #         for data in item:
    #             if data.tag == 'pitch':
    #                 for data2 in data:
    #                     note_data_dict[data2.tag] = data2.text
    #             if data.tag == 'duration':
    #                 if data.text not in duration_dict.keys():
    #                     print('Key Error')
    #                     print(data.text)
    #                     input()
    #                 note_data_dict[data.tag] = duration_dict[data.text]
                
    #             if data.tag == 'staff':
    #                 if beat_count >= 174:
    #                     print(previous_beat_duration)
    #                     #aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaah!
    #                 if len(item.attrib.keys()) != 0 and item.attrib['default-x'] != previous_note_x_data and (previous_note_x_data == '' or abs(float(item.attrib['default-x']) - float(previous_note_x_data)) > 12):
    #                     beat_count += previous_beat_duration
    #                     beat_bar_sum += previous_beat_duration
    #                     previous_beat_duration = note_data_dict['duration']
    #                     previous_note_x_data = item.attrib['default-x']
    #                 elif len(item.attrib.keys()) == 0:
    #                     beat_count += previous_beat_duration
    #                     beat_bar_sum += previous_beat_duration
    #                     previous_beat_duration = note_data_dict['duration']
    #                     previous_note_x_data = ''
    #                 else:
    #                     if abs(float(item.attrib['default-x']) - float(previous_note_x_data)) < 12 and abs(float(item.attrib['default-x']) - float(previous_note_x_data)) > 1:
    #                         print('Double note on line:', float(previous_note_x_data), float(item.attrib['default-x']))

    #                 note_data_dict['beat_count'] = beat_count

    #                 if data.text == '1':
    #                     treble_bar_list.append(note_data_dict)
    #                 elif data.text == '2':
    #                     bass_bar_list.append(note_data_dict)
    #                 else:
    #                     print('Error')
    #                     print(data.text)
    #                     input()
        
    #     elif item.tag == 'backup':
    #         for data in item:
    #             if data.tag == 'duration':
    #                 if data.text not in duration_dict.keys():
    #                     print('Key Error')
    #                     print(data.text)
    #                     input()
    #                 beat_count -= duration_dict[data.text]
    
    # treble_line.append(treble_bar_list)
    # bass_line.append(bass_bar_list)
    # print('Sum of bar:', beat_bar_sum)


def convert_duration_amount(dur_in: int) -> str:
    #if dur_in == 16:
    #    print(dur_in)
    #    print(chr(dur_in + 64))
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
        if index < 50:
            print(note, index)
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
        
        if index < 50:
            print(note_string)
        if note['step'] != '':
            if note['step'] != 'R':
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
            
        # if previous_beat_count == note['beat_count']:
        #     exported_music_data[-1] += note_string
        # else:
        #     #print(note['beat_count'] - previous_beat_count - 1)
        #     for _ in range(note['beat_count'] - previous_beat_count - 1):
        #     #for _ in range(note_duration - 1):
        #         exported_music_data.append('0')
    
        #     exported_music_data.append(note_string)
        #     previous_beat_count = note['beat_count']
        index += 1


    for _ in range(16 - (len(exported_music_data) % 16)):
        exported_music_data.append('0')
    
    exported_music_data = exported_music_data[:]

    with open(file_name + '.txt', 'w') as f:
        end_index: int = 4
        for start_index in range(0, len(exported_music_data), 4):
            f.write(','.join(exported_music_data[start_index:end_index]) + ',\n')
        
            #if end_index % 16 == 0:
            #    f.write('\n')
            end_index += 4
            
        f.write('0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n')
        f.write('0,0,0,0,\n0,0,0,0,\n0,0,0,0,\n0,0,0,0')


export_music_data(file + ' T', treble_line[:])
#export_music_data(file + ' B', bass_line)

