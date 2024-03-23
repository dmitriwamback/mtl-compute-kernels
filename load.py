import subprocess
import datetime

start = datetime.datetime.now()
with open('text.txt', 'r+') as file:

    text = file.read()
    print(len(text))
    subprocess.call(['osascript', 'test.applescript', text])

end = datetime.datetime.now()
print(start-end)
