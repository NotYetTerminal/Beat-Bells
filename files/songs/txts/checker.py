def checker(file_contents: list) -> list:
    flat_convert_to_sharp: dict = {'al':'gs',
                                   'bl':'as',
                                   'cl':'bn',
                                   'dl':'cs',
                                   'el':'ds',
                                   'fl':'en',
                                   'gl':'fs'}
    out_contents: list = []
    full_line: list = []
    line_count: int = 0
    for line in file_contents:
        full_line = line.split(',')
        if len(full_line) != 5 or full_line[-1] != '':
            print(full_line)
            print((line_count/4)*5)
            print('Not five')
            input()
        for index1 in range(len(full_line)):
            beat = full_line[index1]
            if beat == '' and index1 != len(full_line) - 1:
                print(full_line)
                print((line_count/4)*5)
                print('Wrong nothing')
            if beat != '0' and beat != '':
                if len(beat) % 4 != 0:
                    print(full_line)
                    print((line_count/4)*5)
                    print('Something missing')
                count: str = ''
                octave: int = 0
                letter: str = ''
                modifier: str = ''
                new_beat: str = ''
                for index in range(len(beat)):
                    if index % 4 == 0:
                        if not beat[index].isupper():
                            print(full_line)
                            print((line_count/4)*5)
                            print('Not uppercase')
                        else:
                            count = beat[index]
                    elif index % 4 == 1:
                        if not beat[index].isdigit():
                            print(full_line)
                            print((line_count/4)*5)
                            print('Not number')
                        else:
                            octave = int(beat[index])
                    elif index % 4 == 2:
                        if not beat[index].islower():
                            print(full_line)
                            print((line_count/4)*5)
                            print('Not lowercase')
                        else:
                            letter = beat[index]
                    elif index % 4 == 3:
                        if beat[index] == 'l':
                            return_value = flat_convert_to_sharp[letter + 'l']
                            letter = return_value[0]
                            modifier = return_value[1]
                            if letter == 'b':
                                octave -= 1
                        elif beat[index] != 'n' and beat[index] != 's':
                            print(full_line)
                            print((line_count/4)*5)
                            print('Not neutral or sharp')
                        else:
                            modifier = beat[index]
                        
                        new_beat += count + str(octave) + letter + modifier
                
                full_line[index1] = new_beat
        
        out_contents.append(','.join(full_line))
        line_count += 1

    out_contents[-1] = out_contents[-1][:-1]

    return out_contents

file_name: str = input('Song name: ')
file_conts: list = []

print('Treble')
with open(file_name + 'T.txt', 'r') as f:
    file_conts = f.read().replace('\n\n','\n').replace(' ','').split('\n')

with open('../' + file_name + 'T', 'w') as f:
    f.write(('\n'.join(checker(file_conts))).replace('d','q').replace('e','r').replace('f','s'))


print('Bass')
with open(file_name + 'B.txt', 'r') as f:
    file_conts = f.read().replace('\n\n','\n').replace(' ','').split('\n')

with open('../' + file_name + 'B', 'w') as f:
    f.write(('\n'.join(checker(file_conts))).replace('d','t').replace('e','u').replace('f','v').replace('a','d').replace('b','e').replace('c','f'))


