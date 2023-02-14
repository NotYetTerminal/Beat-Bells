import os

base_path: str = 'C:/Users/gabor.MCS/Documents/GitHub/68k-project/unused/pictures/qoi_test_images/working/'

index: int = 0
name: str = input('Name plus number: ')
for file in os.listdir(base_path):
    if file.startswith('a') or file.startswith('b'):
        continue
    if file.endswith('.png'):
        os.rename(base_path + file, base_path + name + str(index) + '.png')
        index += 1
    elif file.endswith('.qoi'):
        os.rename(base_path + file, base_path + name + str(index) + '.qoi')
        index += 1
