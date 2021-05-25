#!/bin/bash
#1.0: Scope
# Remove either: roms, gamelists or artwork/mixart/media or all of them from the specified folders.
#2.0: Variables
location="/path/to/roms/"                               # Location of roms to delete. Make sure it ends in /
log_location="/path/to/logs/"                           # Location where logs will be stored. Make sure it ends in /           
#3.0: CODE
#3.1: Log file
log_name=$(basename -- "$0")
log_name+="_"
log_name+=$(date +"%Y-%m-%dT%I:%M:%S-%p")
log_file="$log_location$log_name".log
#3.2: Functions
prompt_confirm() {
  while true; do
  read -p "Are you sure you want to continue? [y/n]: " REPLY
  case $REPLY in
    [yY])
      printf "Ok, moving on.\n"
      return 0
      ;;
    [nN])
      printf "Ok, exiting the script.\n"
      exit
      ;;
    * )
      printf "Please answer y or n.\n"
      ;;
  esac
  done
}
folder_check() {
  if [ ! -e "$location" ]; then
    printf "The folder: $location does not exist.\n"
    printf "Check the folder you want to remove and try again.\n"
    exit
  fi
}
log_check() {
  if [ ! -e "$log_location" ]; then
    printf "The LOG folder: $location does not exist.\n"
    printf "Specify a valid LOG folder and try again.\n"
    exit
  fi
}
logger_printf_scope () {
  eval "$1" > >(sed "s/^/[SCOPE]  - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
logger_printf_sucess () {
  eval "$1" > >(sed "s/^/[SUCESS] - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
logger_printf_error () {
  eval "$1" > >(sed "s/^/[ERROR]  - /" >> "$log_file" )
  #printf does not like the "" under eval. Need to use ''
}
logger_command_error () {
  eval "$1" 1> /dev/null 2> >(sed "s/^/[ERROR]  - /" >> "$log_file" )
}
#3.3: Execute
# Check Folder/Log locagions and confirmm you want to keep on
folder_check
log_check
prompt_confirm
printf "Select which files you want to delete: \n"
# Define which type of files to delete
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
      type="mixart/snap/wheelsw"
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
printf "Ok. Moving on.\n"
logger_printf_scope 'printf "This is the Folder in which files will be deleted: $location \n"'
logger_printf_scope 'printf "These are the type of files to be deleted: $type \n"'
# Delete selected files
case $option in
  roms )
    ls -d -1 "$location"*/ |
    sort |
    while read foldername; do
      find $foldername -maxdepth 1 -type f -exec rm -f {} \;
        if [ $? -eq 0 ]; then
          logger_printf_sucess 'printf "Deleted ROM files in folder: $foldername \n"'
        fi
    done
    ;;
  gamelist )
    ls -d -1 "$location"*/ |
    sort |
    while read foldername; do
      find $foldername -maxdepth 1 -type f -name "gamelist.xml*" -exec rm -f {} \;
      if [ $? -eq 0 ]; then
        logger_printf_sucess 'printf "Deleted Gamelist file in folder: $foldername \n"'
      fi
    done
    ;;
  mixart/snap/wheel )
    ls -d -1 "$location"*/ |
    sort |
    while read foldername; do
      logger_command_error "rm -r "$foldername"mixart/"
      if [ $? -eq 0 ]; then
        logger_printf_sucess 'printf "Deleted mixart files in folder: $foldername \n"'
      fi
      logger_command_error "rm -r "$foldername"snap/"
      if [ $? -eq 0 ]; then
        logger_printf_sucess 'printf "Deleted snap files in folder: $foldername \n"'
      fi
      logger_command_error "rm -r "$foldername"wheel/"
      if [ $? -eq 0 ]; then
        logger_printf_sucess 'printf "Deleted wheel files in folder: $foldername \n"'
      fi
    done
    ;;
  all )
    ls -d -1 "$location"*/ |
    sort |
    while read foldername; do
      logger_command_error "rm -r "$foldername"*"
      if [ $? -eq 0 ]; then
        logger_printf_sucess 'printf "Deleted Files in folder: $foldername \n"'
      fi
    done
    ;;
  *)
    printf "Unknown error. Try again"
    exit
  ;;
esac
printf "Script is finisned. Check the log file located on:\n"
printf "$log_file \n"
