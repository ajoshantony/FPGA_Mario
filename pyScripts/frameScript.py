import csv
#upload new txt file and put "/filename.txt"
ft = open("/titlescreen.txt", "a") 
#upload .csv and put "/name.csv"
f = open('/titlescreen.csv', 'r')
with f:
    reader = csv.reader(f)
    for row in reader:
        for e in row:
            ft.write(str(hex(int(e))[2:])+'\n')
f.close()
ft.close()