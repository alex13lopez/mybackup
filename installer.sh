#!/bin/bash

# Conf ########################
install_dir='/opt/myBackup'
###############################

# Checking root privileges
if ! [ $EUID -eq 0 ]; then
  echo "You need root privileges to run the installer!"
  exit 1
else
  # Filtering last '/' in case it exists
  install_dir=$(echo "$install_dir" | sed 's|/$||')
  if [ ! -e "$install_dir" ]; then mkdir "$install_dir"
  else
    if [ ! -d "$install_dir" ]; then echo "File exists and is not a directory!"; exit 1; fi
  fi
  # Copying files to installation folder and making a link to /sbin/mbackup
  for file in $(ls -1 | grep -v "installer" | grep -v "mbackup.conf"); do
    cp "$file" "$install_dir"
  done
  chmod 755 "$install_dir/mbackup.sh"
  ln -sf "$install_dir/mbackup.sh" "/sbin/mbackup"

  # Beginning set up
  read -p "Do you want to set up mbackup.conf now?[y/n]: " choice
  if [ "$choice" = "y" -o "$choice" = "Y" ]; then
    # Copying mbackup.conf to replace any existing configuration or to first time configuration
    cp ./mbackup.conf "$install_dir"
    # Getting necessary info from user
    read -ep "Do you store the backup in another device?(if not, leave empty): " Device
    if [ -n "$Device" ]; then
      read -p "Do you want to enable the automount option?[Default: yes](yes/no): " automount
    fi
    read -ep "Where do you want to store the backup?: " BkPath
    read -ep "Where is your data folder?[e.g. /home/user]: " DPath
    # This is a filter to remove the last trailing '/'. See mbackup.conf for further details.
    BkPath=$(echo "$BkPath" | sed 's|/$||')
    DPath=$(echo "$DPath" | sed 's|/$||')

    read -a DtoBackup -ep "Which specific dirs you want to backup?(leave empty if you want the entire $DPath)(separated by spaces, and between ''):  "
    read -p "How many days do you want the files to be kept in the backup, since they were deleted?[Default: 30]: " days
    read -ep "Where recovered files will be restored to by default?[Default: $DPath/rescued]:" default_rescue
    read -ep "What will be the owner of the recovered files?(your username):  " user
    read -p "Should hidden files be shown?[Default: hide](hide/show): " hidden_files
    read -p "Should device_check() be verbose?[Default: false](true/false): " verbose

    # Modifying mbackup.conf skeleton
    sed -i "/BkPath/s|=.*|='$BkPath'|"  "$install_dir/mbackup.conf"
    sed -i "/DPath/s|=.*|='$DPath'|"  "$install_dir/mbackup.conf"
    if [ -n "$Device" ]; then
      sed -i "/Device/s|=.*|='$Device'|" "$install_dir/mbackup.conf"
      if [ -n "$automount" ]; then
        sed -i "/automount/s|=.*|='$automount'|" "$install_dir/mbackup.conf"
      fi
    fi
    if [ -z "$DtoBackup" ]; then sed -i '/DtoBackup/s|=.*|="$DPath/*"|' "$install_dir/mbackup.conf"; else sed -i "/DtoBackup/s|=.*|=(${DtoBackup[*]})|" "$install_dir/mbackup.conf"; fi
    if [ -n "$days" ]; then sed -i "/days/s|=.*|='$days'|" "$install_dir/mbackup.conf"; fi
    if [ -n "$default_rescue" ]; then sed -i "/default_rescue/s|=.*|='$default_rescue'|" "$install_dir/mbackup.conf"; fi
    if [ -n "$hidden_files" ]; then sed -i "/hidden_files/s|=.*|='$hidden_files'|" "$install_dir/mbackup.conf"; fi
    if [ -n "$verbose" ]; then sed -i "/verbose/s|=.*|='$verbose'|" "$install_dir/mbackup.conf"; fi
    sed -i "/conf_file/s|=.*|='$install_dir/mbackup.conf'|" "$install_dir/mbackup.sh"
    if [ -n "$user" ]; then
      sed -i "/user/s|=.*|='$user'|" "$install_dir/mbackup.conf"
    else
      echo "You did not indicate a user! Go to $install_dir/mbackup.conf and set it up!"
      exit 1
    fi
  else
    echo "OK. Installing without configuration then..."
  fi
fi
exit 0
