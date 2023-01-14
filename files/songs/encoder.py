notes_dict: dict = {'a1': 0,
                    'b1': 1,
                    'c1': 2,
                    'd1': 3,
                    'e1': 4,
                    'f1': 5,
                    'g1': 6,
                    'a2': 7,
                    'b2': 8,
                    'c2': 9,
                    'd2': 10,
                    'e2': 11,
                    'f2': 12,
                    'g2': 13,
                    'a3': 14,
                    'b3': 15}

outputting_data: list = []
# outputting_data structure is
# 4 bit number represents each line for that quarter beat
# msb represents whether it is a sharp or not
# next three represent the length
# 0 rest, 1 1/4, 2 1/2, 3 1/1, 4 1.5/1, 5 2/1, 6 3/1, 7 4/1
# 4 bits * 16 lines gives 64 bits or 8 bytes ber quarter beat


file_name: str = input('File name: ')
with open(file_name + '.txt', 'r') as f:
    song_data: list = f.read().replace('\n', '').split(',')

current_beat_bytes: list = [0, 0, 0, 0, 0, 0, 0, 0]
current_beat_byte_flags: list = [False for _ in range(16)]

line_counter: float = 0
extra_lines: int = 0
for beat_string in song_data:
    current_beat_byte_flags = [False for _ in range(16)]
    if beat_string != '0':
        for beat in beat_string.split(' '):
            if len(beat) == 3:
                beat += '0'
            if len(beat) != 4:
                print('Error length')
                print(line_counter + extra_lines + 1)
                continue

            if beat[1:3] in notes_dict.keys():
                note_numbering: int = notes_dict[beat[1:3]]
                if not current_beat_byte_flags[note_numbering]:
                    # sets the flag for that note to avoid saving sharp and neutral notes
                    current_beat_byte_flags[note_numbering] = True

                    byte_index: int = int(note_numbering // 2)
                    note_number: int = (int(beat[3]) * 8) + int(beat[0])
                    if note_numbering % 2 == 0:
                        note_number *= 16
                    current_beat_bytes[byte_index] += note_number
                else:
                    print('This note has already been registered skipping')
                    print(line_counter + extra_lines + 1)
            else:
                print('Note note found')
                print(line_counter + extra_lines + 1)
    
    outputting_data.extend(current_beat_bytes)
    current_beat_bytes = [0, 0, 0, 0, 0, 0, 0, 0]
    line_counter += 0.25
    if int(line_counter % 4) == 0 and line_counter >= 1 and (line_counter * 10) % 10 == 0:
        extra_lines += 1


with open(file_name, 'wb') as f:
    f.write(bytearray(outputting_data))

print('Done')

