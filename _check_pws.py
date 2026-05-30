import os

pws_dir = 'output/data/Audios'
for fname in sorted(os.listdir(pws_dir)):
    if fname.endswith('.pws'):
        path = os.path.join(pws_dir, fname)
        with open(path, 'rb') as f:
            data = f.read(16)
        print(f'{fname}: first 16 bytes: {" ".join(f"{b:02X}" for b in data)}  ASCII: {repr(data[:4])}')
