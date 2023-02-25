def checker(file_contents: list) -> list:
    out_contents: list = []
    full_line: list = []
    line_count: int = 0
    for line in file_contents:
        full_line = line.split(',')
        if len(full_line) != 5:
            print(full_line)
            print(line_count)
            print('Not five')
            input()
        for beat in full_line:
            if beat != '0' and beat != '':
                if len(beat) % 4 != 0:
                    print(full_line)
                    print(line_count)
                    print('Something missing')
                for index in range(len(beat)):
                    if index % 4 == 0:
                        if not beat[index].isupper():
                            print(full_line)
                            print(line_count)
                            print('Not uppercase')
                    elif index % 4 == 1:
                        if not beat[index].isdigit():
                            print(full_line)
                            print(line_count)
                            print('Not number')
                    elif index % 4 == 2:
                        if not beat[index].islower():
                            print(full_line)
                            print(line_count)
                            print('Not lowercase')
                    elif index % 4 == 3:
                        if beat[index] != 'n' and beat[index] != 's':
                            print(full_line)
                            print(line_count)
                            print('Not neutral or sharp')
        
        out_contents.append(','.join(full_line))
        line_count += 1

    out_contents[-1] = out_contents[-1][:-1]

    return out_contents

file_name: str = input('Song name: ')
file_conts: list = []

print('Treble')
with open(file_name + 'T.txt', 'r') as f:
    file_conts = f.read().replace('\n\n','\n').replace(' ','').replace('d','q').replace('e','r').replace('f','s').split('\n')

with open('../' + file_name + 'T', 'w') as f:
    f.write('\n'.join(checker(file_conts)))


print('Bass')
with open(file_name + 'B.txt', 'r') as f:
    file_conts = f.read().replace('\n\n','\n').replace(' ','').replace('d','t').replace('e','u').replace('f','v').replace('a','d').replace('b','e').replace('c','f').split('\n')

with open('../' + file_name + 'B', 'w') as f:
    f.write('\n'.join(checker(file_conts)))


