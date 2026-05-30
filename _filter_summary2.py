import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
with open(r'C:\Users\Shadow\.cursor\projects\c-Users-Shadow-Desktop-notes-on-the-released-game\agent-tools\d0dc3928-fede-4fc6-b61c-28ce80806ec7.txt', encoding='utf-8', errors='replace') as f:
    for line in f:
        stripped = line.strip()
        if stripped.startswith('ASET['):
            continue
        if stripped.startswith('[') and '/2197]' in stripped:
            continue
        print(line, end='')
