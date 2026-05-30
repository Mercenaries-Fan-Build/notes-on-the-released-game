import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
with open(r'C:\Users\Shadow\.cursor\projects\c-Users-Shadow-Desktop-notes-on-the-released-game\agent-tools\52eccf36-5721-4f8e-9f3f-c437f593f957.txt', encoding='utf-8', errors='replace') as f:
    for line in f:
        if not line.strip().startswith('ASET['):
            print(line, end='')
