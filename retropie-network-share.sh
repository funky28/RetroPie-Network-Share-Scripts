#!/bin/bash
#1.0: Scope
# Mount the network location share contaning roms (network roms). Move retropie roms folder to a new location (local roms). 
# Create an overlay with: network share + local roms + local gamelist/artwork
# Update autostart.sh script with new overlay and network mount. Tweaked livewire.py script to fix music location (local roms)
# Logging of critical success tasks, warnings and erros to custom file.
# THE ONLY VARIABLE THAT COULD NEED AN UPDATE IS= $retropie_config
#2.0: Variables:
#2.1 Constants:
overlay_folder="overlay_files/"                                               # Name of the Overlay parent folder
overlay_mount_name="retropie_network_overlay"                                 # Name of the overlay mount
script_id="#PI-REPTROPIE-NETWORK-SHARE-SCRIPT---------------------------+"    # Deliniator for this script
#2.2: Folder Locations - Make sure / is at the end for folders
retropie_config="/home/pi/RetroPie/"                                          # Location of the retropie config folder
folder_roms="$retropie_config"roms                                            # Location of the original retropie rom folder
folder_overlay="$retropie_config$overlay_folder"                              # Location of the overlay folder tree
folder_overlay_roms_network="$folder_overlay"roms_network                     # Location of the network share roms
folder_overlay_roms_local="$folder_overlay"roms_local                         # Location of the new retropie rom folder
folder_overlay_artwork="$folder_overlay"artwork                               # Location of the local gamelist and artwork (same rom file tree)
folder_overlay_logs="$folder_overlay"logs                                     # Location of the script logs
folder_overlay_work="$folder_overlay"work                                     # Location of the overlay working folder
folder_overlay_settings="$folder_overlay"settings                             # Location of the overlay settings
folder_livewire_music_original="$retropie_config"roms/music                   # Location of the original retropie music folder
folder_livewire_music_modified="$folder_overlay"roms_local/music              # Location of the new retropie music folder
#2.3: File Locations
file_credentials="$folder_overlay_settings"/cifs_credentials                  # File name/location of the network credentials
script_on="$folder_overlay_settings"/network-script-ON                        # File name/location for script ON status 
script_off="$folder_overlay_settings"/network-script-OFF                      # File name/location for script OFF status
autostart="/opt/retropie/configs/all/autostart.sh"                            # Location of the autostart script
file_livewire="/home/pi/.livewire.py"                                         # Location of the livewire file
#3.0: Code:
#3.1: Set up logs:
log_name=$(basename -- "$0")
log_name+="_"
log_name+=$(date +"%Y-%m-%dT%I.%M.%S-%p")
log_file="$retropie_config$log_name".log
#3.2: Functions:
#3.2.1: File checks:
check_dir () {
  if [ ! -d "$1" ]; then
    printf "$2 folder does not exist. Please configure inside the script.\n"
    dir_check_status="exit" 
  elif [[ "$1" != */ ]]; then 
    printf "Please make sure the following location ends with a /, configure inside the script: $1\n"
    dir_check_status="exit" 
  fi
}
check_file () {
  file_check_status="" 
  if [ ! -e "$1" ]; then
    printf "$2 file does not exist. $3\n"
    file_check_status="exit" 
  fi
}
check_mount () {
  mount_network="$folder_overlay_roms_network"
  mount_overlay="$folder_roms"
  mount_test=$(df -aTh | grep -e "$mount_network")
    if [[ "$mount_test" == *"$mount_network"* ]]; then
    printf "There is a Network mount point at: $mount_network \n"
    mount_check_status="exit"
  fi
  mount_test=$(df -aTh | grep -e "$mount_overlay")
  if [[ "$mount_test" == *"$mount_overlay"* ]]; then
  printf "There is an Overlay mount point at: $mount_overlay \n"
  mount_check_status="exit"
  fi
  if [ "$mount_check_status" == "exit" ]; then 
    printf "Unmount Overlay/Share before proceeding. Exiting the script. \n"
    exit 
  fi
}
check_script_status_on () {
  if [ -e $script_on ]; then
    printf "The script  has been previoously turned on. Run the script again and select: Turn Off.\n"
    exit
  fi
}
check_script_status_off() {
  if [ -e $script_off ]; then
    printf "The script  has been previoously turned off. Run the script again and select: Turn On.\n"
    exit
  fi
}
check_script_id () {
  if [[ ! -z $(grep "$script_id" "$1") ]]; then 
    file_warning_print="$1"
    logger_warning "Previous script installation detected on file: $file_warning_print"
  fi
}
#3.2.2: Prompts:
promt_confirm() {
  while true; do
    read -p "Are you sure $1? [y/n]: " REPLY
    case $REPLY in
      [Yy] )
        printf "Ok, moving on.\n"
        return 0
        ;;
      [Nn] )
        printf "Ok, Exiting the Script.\n"
        exit
        ;;
      * ) 
        printf "Please answer y or n.\n"
        ;;
    esac
  done 
}
#3.2.3: Loggers:
logger_global_error_start () {
  exec 2> >(sed "s/^/[ERROR]   - /" >> "$log_file" )
}
logger_global_error_end () {
  exec 2>&1
}
logger_sucess () {
  if [ $? -eq 0 ]; then
    printf "$1 \n" > >(sed "s/^/[SUCESS]  - /" >> "$log_file" )
  fi
}
logger_warning () {
  printf "$1 \n" > >(sed "s/^/[WARNING] - /" >> "$log_file" )
}
logger_scope () {
  printf "$1 \n" > >(sed "s/^/[SCOPE]   - /" >> "$log_file" )
}
logging_start () {
  logger_global_error_start
  logger_scope "This is the RetroPie folder location: $retropie_config"
  logger_scope "Script configuration type: $response"
}
logging_end () {
  mv "$log_file" "$folder_overlay_logs"
  printf "Script has finished. Check log file on: $folder_overlay_logs \n"
  logger_global_error_end
}
#3.2.4: Settings:
settings_dir () {
  #Check/Make directories:
  declare -a dir_overlay=("artwork" "logs" "roms_local" "roms_network" "settings" "work")
  if [ ! -d "$folder_overlay" ]; then
    mkdir "$folder_overlay"
  fi
  for val in "${dir_overlay[@]}"; do
    dir_new="$folder_overlay"
    dir_new+="$val"
    if [ ! -d "$dir_new" ]; then
      mkdir "$dir_new"
      logger_sucess "Created Folder: $dir_new"
    fi
  done 
}
settings_credentials () {
  #Create credentials file for the first time:
  printf "Enter the share location (i.e. //10.0.1.xx/path/to/your/roms): " 
  read input_share
  printf "Enter share user name: "
  read input_user
  printf "Enter share user password: "
  read input_password
  printf "username=$input_user\n" > "$file_credentials"
  printf "password=$input_password\n" >> "$file_credentials"
  printf "share=$input_share" >> "$file_credentials"
  chmod 600 "$file_credentials"
  logger_sucess "Credentials file location: $file_credentials"
}
#3.2.5: Commands:
command_script_id () {
  sed -i -e '$a\' "$2"                #add a new line to the end of the file, if it does not exists.
  id_deliniator="$script_id"
  id_deliniator+="$1"
  printf "$id_deliniator\n" >> $2
}
command_mount_autostart () {
  share_location=$(cat "$file_credentials" | grep -E "share" | awk -F"[=]" '{print $2;exit}')
  mount_location="$folder_overlay_roms_network"
  printf "sudo mount -t cifs -o credentials=$file_credentials,nounix,noserverino \"$share_location\" \"$mount_location\" \n" >> "$autostart"
  logger_sucess "Updated script to include share mount at: $autostart"
}
command_overlay_autostart () {
  lower1="$folder_overlay_artwork"
  lower2="$folder_overlay_roms_network"
  upper="$folder_overlay_roms_local"
  work="$folder_overlay_work"
  merged="$folder_roms"
  printf "sudo mount -t overlay $overlay_mount_name -o lowerdir="$lower1":"$lower2",upperdir="$upper",workdir="$work" "$merged" " >> "$autostart"
  logger_sucess "Updated script to include overlay mount at: $autostart"
}
command_delete_script_id () {
  start="$script_id"BEGIN
  end="$script_id"END
  sed -i "/$start/,/$end/d " "$autostart"
  logger_sucess "Updated script to remove script lines at: $autostart"
}
command_livewire () {
  start="$script_id"BEGIN
  end="$script_id"END
  if [ "$1" == "modified" ]; then
    if [ ! -d "$file_livewire"-original ]; then
      cp "$file_livewire" "$file_livewire"-original
    fi
    cp "$file_livewire" "$file_livewire"-original
    mv -f "$file_livewire"-original "$folder_overlay_settings"
    # use | on the last sed as a deliniator, to avoid issues with / and folders
    sed -i "/^musicdir =.*/i $start
      /^musicdir =.*/a $end
      s|$folder_livewire_music_original|$folder_livewire_music_modified|g" "$file_livewire" 
    logger_sucess "Modified file: ~/home/.livewire.py to change the music folder location to: $folder_livewire_music_modified"
  fi
  if [ "$1" == "original" ]; then
    # use| as a deliniator, to avoid issues with / and folders
    sed -i "/$start/d
      /$end/d
      s|$folder_livewire_music_modified|$folder_livewire_music_original|g" "$file_livewire" 
    logger_sucess "Modified file: ~/home/.livewire.py to change the music folder location back to the original: $folder_livewire_music_original"
    
  fi
}
command_unmount () {
  share_location=$(cat "$file_credentials" | grep -E "share" | awk -F"[=]" '{print $2;exit}')
  sudo umount "$overlay_mount_name"
  logger_sucess "Unmounted Overlay Mount.\n"
  sudo umount "$share_location"
  logger_sucess "Unmounted Network Share.\n"
}
command_invert_script_id () {
  start="$script_id"BEGIN
  end="$script_id"END
  print_script_id=$(sed -n "/$start/,/$end/p " "$1")
  delete_script_id=$(sed "/$start/,/$end/d " "$1")
  printf "$print_script_id\n$delete_script_id\n" > "$1" 
}
command_delete_settings () {
  promt_confirm "you want to delete all custom overlay config, files and folders (including logs)"
  check_script_status_on
  rm -rf "$folder_overlay"
}
command_finishing_on () {
  mv "$retropie_config"roms/* "$folder_overlay_roms_local"
  logger_sucess "Moved original retropie rom folder to: $folder_overlay_roms_local"
  rm -f "$script_off"
  printf "Network share is ON.\n" > "$script_on"
}
commnad_finishing_off () {
    mv "$folder_overlay_roms_local"/* "$retropie_config"roms
    logger_sucess "Moved contents of "$folder_overlay_roms_local" folder to the original retropie rom location"
    rm -f "$script_on"
    rm -f "$file_credentials"
    printf "Network share is OFF.\n" > "$script_off"
}
command_reboot () {
  printf "The system needs to reboot now for the changes to take effect.\n"
  while true; do
  read -p "Do you want to reboot now (y or n)?: " answer
  case $answer in
    [Yy]* )
      printf "OK, rebooting in 10 seconds.\n"
      sleep 10
      sudo reboot
      ;;
    [Nn]* )
      break
      ;;
    * )
      printf "Please answer y or n.\n"
      ;;
    esac
  done
}
test () {
  printf "$retropie_config\n"
}
#3.3: Run Checks:
check_dir "$retropie_config" "Retropie configuration"
if [ "$dir_check_status" == "exit" ]; then exit; fi
#3.4 Execute:
printf "Select what you want to do: \n"
select response in "Turn ON ROM network share" "Turn OFF ROM network share" "Fix network share credentials" \
  "Unmount overlay share (no log)" "Unmount network share (no log)"  "Uninstall Overlay Script (no log)" \
  "Things to do (no log)" "Test" "EXIT" ; do
  case $response in
    "Turn ON ROM network share" )
      check_mount
      check_script_status_on
      logging_start
      settings_dir
      settings_credentials
      check_script_id "$autostart"
      command_script_id "BEGIN" "$autostart"
      command_mount_autostart
      command_overlay_autostart
      command_script_id "END" "$autostart"
      command_invert_script_id "$autostart"
      command_livewire "modified"
      command_finishing_on
      logging_end
      command_reboot
      break
      ;;
    "Turn OFF ROM network share" )
      check_script_status_off
      logging_start
      command_unmount
      command_delete_script_id
      command_livewire "original"
      commnad_finishing_off
      logging_end
      command_reboot
      break
      ;;
    "Fix network share credentials" )
      check_file "$file_credentials" "Credentials file"
      if [ "$file_check_status" == "exit" ]; then exit; fi
      logging_start
      command_delete_script_id
      settings_credentials
      command_script_id "BEGIN" "$autostart"
      command_mount_autostart
      command_overlay_autostart
      command_script_id "END" "$autostart"
      command_invert_script_id "$autostart"
      logging_end
      command_reboot
      break
      ;;
    "Unmount overlay share (no log)" )
      sudo umount "$overlay_mount_name"
      if [ $? -eq 0 ]; then
        printf "Overlay un-mount was sucessful \n"
      fi
      break
      ;;
    "Unmount network share (no log)" )
      share_location=$(cat "$file_credentials" | grep -E "share" | awk -F"[=]" '{print $2;exit}')
      sudo umount "$share_location"
      if [ $? -eq 0 ]; then
        printf "Netwwork share un-mount was sucessful \n"
      fi
      break
      ;;
    "Uninstall Overlay Script (no log)" )
      command_delete_settings
      command_reboot
      break 
      ;;
    "Things to do (no log)" )
      printf "Update timezone via sudo raspi-config.\n"
      printf "Update hostname via sudo raspi-config.\n" 
      printf "Update password via sudo raspi-config.\n" 
      printf "Enable wait for network option via sudo raspi-config.\n" 
      break
      ;;
    "Test" )
      test
      break
      ;;
    "EXIT")
      exit
      ;;
    *) 
      printf "Invalid option $REPLY, try again.\n"
      ;;
  esac
done
