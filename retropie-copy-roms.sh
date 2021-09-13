#!/bin/bash
#1.0: Scope
# Copy either: roms, gamelists or artwork/mixart/media or all of them from the specified folders.
# great from moving the entire roms location from one place to another, or if you want to split the media files.
#2.0: Variables:
#2.1: Constants:
# #2.2: Locations 
rom_location="/paths/to/your/roms/"                                           #Location of ROMS to copy from. Make sure it ends in / 
rom_destination="/path/to/new/roms/"                                          #Location of ROMS to copy to. Make sure it ends in / 
log_location="/path/to/logs/"                                                 #Location where logs will be stored. Make sure it ends in / 
#3.0: Code:
#3.1: Set up logs:
log_name=$(basename -- "$0")
log_name+="_"
log_name+=$(date +"%Y-%m-%dT%I:%M:%S-%p")
log_file="$log_location$log_name".log
#3.2: Functions:
file_check () {
  if [ ! -d "$1" ]; then
    printf "$2 folder does not exist. Please configure inside the script.\n"
    file_check_status="exit" 
  fi
  }
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
logger_command_error () {
  eval "$1" 1> /dev/null 2> >(sed "s/^/[ERROR]   - /" >> "$log_file" )
}
logger_printf_scope () {
  eval "$1" > >(sed "s/^/[SCOPE]   - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
logger_printf_sucess () {
  eval "$1" > >(sed "s/^/[SUCESS]  - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
logger_printf_warning () {
  eval "$1" > >(sed "s/^/[WARNING] - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
logger_printf_error () {
  eval "$1" > >(sed "s/^/[ERROR]   - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
#3.3: Checks:
file_check "$rom_destination" "ROM Destination"
file_check "$rom_location" "ROM Location"
file_check "$log_location" "LOG Location"
if [ "$file_check_status" == "exit" ]; then exit; fi
#3.3 Excecution:
# Define which type of files to copy
printf "Select which files you want to copy: \n"
select option in all roms gamelist mixart/snap/wheel EXIT ; do
  case $option in
    roms )
      type="roms"
      break
      ;;
    gamelist )
      type="gamelist"
      break
      ;;
    mixart/snap/wheel )
      type="mixart/snap/wheel"
      break
      ;;
    all )
      type="all"
      break
      ;;
    EXIT)
      exit
      ;;
    *) 
      printf "Invalid option $REPLY, try again.\n"
      ;;
  esac
done
#Get the ROM files to copy from the rom location
rom_to_copy=( $(find "$rom_location" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort) )
printf "Here is the list of ROMS to copy into folder: \"$rom_destination\" \n"
for i in "${rom_to_copy[@]}"; do 
  if [ "${rom_to_copy[-1]}" !=  "$i" ]; then 
    printf "$i, "
  elif [ "${rom_to_copy[-1]}" ==  "$i" ]; then
    printf "and $i.\n"
  fi
done
promt_confirm "these are the ROMS you want to copy"
logger_printf_scope 'printf "These are the ROMs to copy: ${rom_to_copy[*]}.\n"'
#start log:
logger_printf_scope 'printf "This is the Folder in which files will be copied FROM: $rom_location \n"'
logger_printf_scope 'printf "This is the Folder in which files will be copied TO: $rom_destination \n"'
logger_printf_scope 'printf "These are the type of files to be copied: $type \n"'
# copy selected files
case $option in
  roms )
    for dir in "${rom_to_copy[@]}"; do 
      if [ ! -d "$rom_destination$dir" ]; then
        logger_printf_warning 'printf "ROM Folder: $dir, does not exist in the destination folder.\n"'
      else 
        logger_command_error "find "$rom_location$dir" -maxdepth 1 -type f -exec cp -r {} "$rom_destination$dir" \;"
        logger_command_error "find "$rom_location$dir" -maxdepth 1 -type f -exec cp -r {} "$rom_destination$dir" \;"
        if [ $? -eq 0 ]; then
          logger_printf_sucess 'printf "Copy of ROM files in folder: "$dir" was completed. \n"'
        fi
      fi
    done
  ;;
  gamelist )
    for dir in "${rom_to_copy[@]}"; do 
      if [ ! -d "$rom_destination$dir" ]; then
        logger_printf_warning 'printf "ROM Folder: $dir, does not exist in the destination folder.\n"'
      else 
        if [ ! -e "$rom_location$dir/gamelist.xml" ]; then
          logger_printf_warning 'printf "ROM Folder: $dir, does not has a gamelist file.\n"'
        else 
          logger_command_error "cp -r "$rom_location$dir"/gamelist.xml* "$rom_destination$dir""
          if [ $? -eq 0 ]; then
            logger_printf_sucess 'printf "Copy of all gamelist files from "$dir" was completed.\n"'
          fi
        fi
      fi
    done
  ;;
  mixart/snap/wheel )
    for dir in "${rom_to_copy[@]}"; do 
      if [ ! -d "$rom_destination$dir" ]; then
        logger_printf_warning 'printf "ROM Folder: $dir, does not exist in the destination folder.\n"'
        else 
        declare -a msw=("mixart" "snap" "wheel")
        for val in "${msw[@]}"; do
          if [ ! -d "$rom_location$dir/$val" ]; then
            logger_printf_warning 'printf "ROM Folder: $dir, does not has a $val folder.\n"'
          else
            logger_command_error "cp -r "$rom_location$dir"/"$val" "$rom_destination$dir"/"$val""
            if [ $? -eq 0 ]; then
              logger_printf_sucess 'printf "Copy of $val files from "$dir" was completed.\n"'
            fi
          fi
        done 
      fi
    done
  ;;
  all )
    for dir in "${rom_to_copy[@]}"; do 
      if [ ! -d "$rom_destination$dir" ]; then
        logger_printf_warning 'printf "ROM Folder: $dir, does not exist in the destination folder.\n"'
        else 
        logger_command_error "cp -r "$rom_location$dir"/. "$rom_destination$dir""
        if [ $? -eq 0 ]; then
          logger_printf_sucess 'printf "Copy of all files from "$dir" was completed.\n"'
        fi
      fi
    done
  ;;
  *)
    printf "Unknown error. Try again"
    exit
  ;; 
esac 
printf "Script is finished. Check the LOGs on "$log_file"\n"