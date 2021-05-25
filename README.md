# RetroPie-Scripts
Bundle of custom retropie scripts (bash) to run special/repetitive tasks on a raspberry pi4. 
These have been tested on a raspberry pi 4 with Virtualman v1.98x-4.5.7
These scripts can seriusly damage your system or delete files. Always create a backup before attempting to run any of these.
I will take no responsability if your systems wont work or breaks.

# retropie_copy-roms:
Copy either: roms, gamelists or artwork/mixart/media or all of them from the specified folders.
Great from moving the entire roms location from one place to another, or if you want to split the media files.
Just update the three main variables inside the script to point to the folder and log locations.

# retropie_remove-roms
Remove either: roms, gamelists or artwork/mixart/media or all of them from the specified folders.
Just update the two main variables inside the script to point to the folder and log locations.

# retropie-network-share
Mount the network location share contaning roms (network roms). Move retropie roms folder to a new location (local roms). 
Create an overlay with: network share + local roms + local gamelist/artwork
Update autostart.sh script with new overlay and network mount. Tweaked livewire.py script to fix music location (local roms)
Logging of critical success tasks, warnings and erros to custom file.
Loosly Based on the Eazy-Hax-Retropie-Toolkit:
https://github.com/Shakz76/Eazy-Hax-RetroPie-Toolkit
