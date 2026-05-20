## Assumptions

1. You know how to copy files, and run python scripts in the terminal.
2. You have [a copy of the game; if you don't have a copy archive.org has a copy listed as abandonware](https://archive.org/download/mc-2_20251112/Mercenaries%202%20World%20in%20Flames.zip)
3. You're on a windows 10+ machine.
4. You have [Python installed in Windows](https://www.python.org/downloads/windows/).
5. You have downloaded a copy of the [32 bit xinput1_3.dll from Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/xinput1_3-Win32.zip)
6. You have [downloaded a copy of bsdiff](https://github.com/reitowo/bsdiff-win/releases/tag/v4.3) 
7. You have a copy of this repository (assuming you click the download zip button, it should be called `notes-on-the-released-game-main.zip`)
8. You have a backup of your Mercenaries2.exe and xinput1_3.dll

```
Games/
├──Mercenaries 2 World in Flames/
│   ├── Mercenaries2.exe
│   ├── data/
│   │   ├── shell.wad
│   │   ├── vz.wad
│   │   ├── English.wad
│   │   └── ... (other .wad packs)
│   ├── Precache/
│   └── ... (other files)
└── ... other games?

workspace/
├──xinput1_3.dll.zip
├──bsdiff-v4.3-win-x86.zip
└──notes-on-the-released-game-main.zip
```

## Verify the game opens DRM

Try to run the Mercenaries2.exe, it should prompt you with the DRM request for EA; if the game works for you without doing anything you do not need to proceed :smile:


## Prepare your workspace

```
workspace/
├──bsdiff-v4.3-win-x86/     
│   ├── bsdiff.exe
│   └── bspatch.exe
├──xinput1_3-Win32/     
│   ├── xinput1_3.dll
│   └── xinput1_3-Win32.SHA512
└──notes-on-the-released-game-main/
    └── tools/
        ├── bin/                     <-- Create this bin folder
        ├── apply_securom_patch.py
        └─  ...
```
## Instructions

1. Rename the `Games/Mercenaries 2 World in Flames/xinput1_3.dll` to `Games/Mercenaries 2 World in Flames/xinput1_3Hooked.dll`
1. Move the `workspace/xinput1_3.dll` to your `Games/Mercenaries 2 World in Flames/` folder.
1. Move the `workspace/bsdiff-v4.3-win-x86/*.exe` files into the `workspace/notes-on-the-released-game-main/tools/bin/` folder.
1. Create an `updates` folder in your Mercenaries 2 game folder at `Games/Mercenaries 2 World in Flames/updates`
1. Create a `bin` folder in your notes-on-the-released-game-main/ folder at `workspace/notes-on-the-released-game-main/tools/bin/`
1. Open a terminal and navigate to your copy of this repository in `workspace/notes-on-the-released-game-main`
1. Run the following command **changing the parts you need for your machine** 

```
python -m venv .venv
.venv\Scripts\pip install -r requirements.txt
.venv\Scripts\python tools/apply_securom_patch.py 'C:\Whereever\Games\Mercenaries 2 World in Flames\Mercenaries2.exe' --output 'output\Mercenaries2.exe'
```

This will detect whether you have the 1.0 or 1.1 version of the PC game, and patch accordingly. For 1.0 games it'll update you to 1.1, and then apply the DRM patch, otherwise it'll just apply the DRM patch.

1. Once the above is complete, copy the `Mercenaries2.exe` file from the `workspace/notes-on-the-released-game-main/output/Mercenaries2.exe` to your `Games/Mercenaries 2 World in Flames/` directory
1. Take the `workspace/notes-on-the-released-game-main/output/pmc_bb.dll` file and put it in your `Games/Mercenaries 2 World in Flames/` directory (next to `Mercenaries2.exe`).


## Start the game

It should take just a second before launching, unless you know you have slow disks this should be a fairly quick process.

For a quick sanity check, your folder structure in the game should look like this
```
Games/
├──Mercenaries 2 World in Flames/
│   ├── pmc_bb.dll
│   ├── Mercenaries2.exe
│   ├── xinput1_3.dll
│   ├── xinput1_3Hooked.dll
│   ├── data/
│   │   ├── shell.wad
│   │   ├── vz.wad
│   │   ├── English.wad
│   │   └── ... (other .wad packs)
│   ├── Precache/
│   └── ... (other files)
└── ... other games?
```

You can delete the `workspace/` related code and files. 