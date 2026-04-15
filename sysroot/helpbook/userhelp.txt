WELCOME
=======

First of all welcome to **Aplaun OS**.

Now as a user you have some simple things to do.
Most if not all can be done here.

BASIC USES
----------

Mostly you'll need to -

0. Install and run **Aplaun OS**
1. Open games and applications
2. Check folders
3. Open and Change files
4. Change settings

We'll explain them all *briefly* here
with just enough information to allow you to
do all these things and *explore* the new.

### Install Aplaun

###### Recommended: Copy all files from
**copythis folder** to the drive too.

[See How-To Install Video](http://youtu.be/JYMeiAToqoE)

Use any of the following methods to install it.
You can even check out videos or blogs.

#### By USB Image Tool (recommended) -

	1. go in usbit folder.
	2. run USBit Image Tool (with admin rights).
	3. Select your USB drive / flash drive.
	4. Click Restore.
	5. Select BOOT.IMG from the downloaded folder.
	6. The Bootloader is copied.
	7. Copy the latest kernel.com from downloads.
	8. Copy apps you like.

#### By HxD -

	1. run HxD (with admin rights).
	2. From Extras menu select Open disk image...
	3. Select the drive correctly (otherwise you could corrupt your hard drive)
	4. It would be a Removable drive.
	5. Open BOOT.IMG from the downloaded folder.
	6. Select all and Copy the bootloader.
	7. Paste it at the start of your drive (Sector 0).
	8. Make sure you had selected your required drive and press SAVE.
	9. The Bootloader is copied.
	10. Copy the latest kernel.com from downloads
	11. Copy apps you like

### Run Aplaun

1. Insert USB in PC (or the drive you installed it in)
2. Start computer
3. Use BIOS to change settings to boot USB drive with highest priority.
4. Use any of the starting applications that are run as autorun or skip by enter.
5. Check out our logo :)
6. And type `roam` > Press Enter on command line
7. Access all folders this way by `roam` or `z` command.

### How to Open Games and Applications

1. Use `roam` to select any executable file and it will be run.
2. Or at command line, type its name when you're in its folder
3. To access apps from other folders, add them to path (addpathc).
4. Select games and apps to run in a shell.
5. Or if you want to run it automatically on every start,
add its name in confg.bat file.
6. Enter arguments for the app by pressing space and entering values.

### Check folders

1. `cd foldername` - to open a folder
2. `dir` or `q` - to list folder items.
3. `roam` or `z` - to use a user-friendly selector.

### File Handling

1. `fname` or `nm' - to name a file to be operated upon.
2. `q` or select the file from the selector to load it in memory.
3. `fnew` to create a new file with the name provided with `fname`.
4. `del` to delete the file with given name.
5. `rename` to provide a new name to the file.
6. `copy` to create a copy of the file in the current folder.

### Settings

1. Press F2 or enter `setting` to open dialog for this.
2. Use **quick settings** to show current settings.
3. Each label in the quick setting output can be used to
edit the given setting.
4. Use `advanced` mode to show more details about the file.
