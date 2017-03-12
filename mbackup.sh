#!/bin/bash

################################################################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Version: 4.1.1-beta
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
# Important: Set the vars below to suit your configuration.
# More IMPORTANT: This script is in BETA version, so report any bugs to me please.
#                 Also don't add any nor remove any line, because in the device_check() I tell sed to only act in line 34, because otherwise,
#                 it will edit itself cause the pattern will match to itself.
# Note: It's not mandatory to have the backup separated in another partition, but It is highly recommended,
#	    because if a ransomware ciphers your disk it will also cipher your backup, thus the
#	    purpose of having a backup will become useless.
################################################################################################################################################

################################################################################ CONF VARS ########################################################################################################

# Full path where the backup will be stored
# IMPORTANT NOTE: Do not add a trailing '/' e.g: /mnt/backup instead of /mnt/backup/
BkPath=''

# Full path of the location of your root data folder
# IMPORTANT NOTE: Do not add a trailing '/' e.g: /home/aren instead of /home/aren/
DPath=''

# Specific directories to backup, separated by spaces (and full path)
DtoBackup=('')

# Put in the var $Device the device you use to store the backup in case you use another partition of the disk or another device, this way, the script will be able to check if it's mounted or not
# The $automount option is highly recommended to be set to 'yes', but you can set it to 'no' if you want.
Device=''
automount='yes' #Default value: 'yes'. Choose between 'yes' or 'no'.

# Days that files will be kept in the backup if they were removed from data folder. Default days='30'
days='30'

# Default folder when recovered files/folders will be restored. Default value: default_rescue="$DPath/rescued"
default_rescue="$DPath/rescued"

# Should hidden files and folders be shown in recovery CLI?
# This is to set the default behavior, you can change this later on interactively
# Default option is 'hide'. You can choose either 'hide' or 'show'.
hidden_files='hide'

# This makes device_check() verbose. Default value: false. You can set it to "true" or "false".
verbose="false"
###################################################################################################################################################################################################

#Colors
red=`tput setaf 1`
yellow=`tput setaf 3`
blackback=`tput setab 0`
reset=`tput sgr0`
blue=`tput setaf 4`
cyan=`tput setaf 6`
bold=`tput bold`
green=`tput setaf 2`

# This is to make sure 'clear' is not a custom alias such as 'printf "\033c"'. The reason is because causes the mbackup CLI to have delays.
alias clear="\clear"
# Same as clear but with ls.
alias ls="\ls"


function usage(){
	echo """Usage: mbackup <OPTION>
       OPTION:
		<noargs>      -->  Goes to main menu
		-b --backup   -->  Performs a backup and exits
		-c --clean    -->  Performs a clean of older removed files and exits
		-o --open     -->  Opens the backup device with nautilus and exits
		-r --recovery -->  Goes directly to recovery CLI
		-i --info     -->  Shows info about the backup device
		-h --help     -->  Shows this help"""

}

function quit(){
	if [ -n "$Device" ]; then
		if df | grep -q "$Device"; then umount -f "$Device"; fi
	fi
	exit 0
}

function device_check() {
	if [ -n "$Device" ]; then
		if ! df | grep -q "$Device"; then
			if [ "$automount" = "no" ]; then
				echo; echo "${red}Error: $Device is not mounted and automount option is disabled${reset}"; echo
				return 1
			elif [ "$automount" = "yes" ]; then
				if [ "$verbose" = "true" ]; then
					echo; echo "${green}Device $Device is not mounted but automount is enabled so $Device will be mounted${reset}"; echo
				fi
				mount "$Device" "$BkPath"
				return 0
			else
				read -t 20 -p "${yellow}Warning: '$automount' is not a valid value for automount, do you want to mount the device now and set the automount var to 'yes'?[y/n]: ${reset}" choice
				case $choice in
					yes|Yes|Y|y) mount "$Device" "$BkPath";  sed -in "34s/auto.*#/automount='yes' #/" $0 ;;
					no|No|N|n) echo "${red}Then I am not able to continue, exiting program...${reset}"; return 1 ;;
					*) echo -e "${yellow}\nWarning: Question was not answered or was not answered correctly, assuming unattended script. Mounting $Device...${reset}"; mount "$Device" "$BkPath" ;;
				esac
				return 0
			fi
		else
			# Device is already mounted
			if [ "$verbose" = "true" ]; then
				echo; echo "${green}Device $Device is already mounted${reset}"; echo
			fi
			return 0
		fi
	else
		# $Device var is not set up so assuming the backup is not in another partition/device
		if [ "$verbose" = "true" ]; then
			echo; echo "${green}There is no device to mount, resuming${reset}"; echo
		fi
		return 0
	fi
}

function infor(){
	if device_check; then	df -h "$Device"; umount -f "$Device"; fi
}

function backup(){
	if [ -n "$Device" ]; then
		if ! device_check; then	exit 1; fi
	fi
	for dir in ${DtoBackup[@]}
	do
		if [[ ! -e $dir  ]]; then
			echo "${yellow}Warning: Directory $dir does not exist, please make sure you typed the path correctly, skipping...${reset}"
			continue
		else
			cp -ruv --no-preserve=all "$dir" "$BkPath"
		fi
	done
	find "$BkPath" -type d -exec chmod -R 770 {} \;
	find "$BkPath" -type f -exec chmod -R 660 {} \;
	if [ -n "$Device" ]; then
		umount -f "$Device"
	fi
}

function open(){
	if [ -n "$Device" ]; then
		if ! device_check; then exit 1; fi
	fi
	clear
	nautilus "$BkPath" & > /dev/null
	echo "${bold}${green}Type enter when you finished...${reset}"
	read pause
	nautilus -q
	if [ -n "$Device" ]; then
		umount -f "$Device"
	fi
}

function available_commands() {
	clear
	echo """Available Commands
			 OPTION:
			 ..			--> Goes to parent folder (in navigation mode)
			 r			--> Enters recovery mode (in navigation mode)
			 n			--> Enters navigation (in recovery mode)
			 q			--> Quits program
			 hide		--> Hides hidden files
			 show		--> Shows hidden files
			 h      --> Shows this help"""
	echo; read -p "${green}Press enter to continue...${reset}"
	clear
}

function list_format() {
	if [ "$hidden_files" = 'hide' ]; then
		extra_args=''
	elif  [ "$hidden_files" = 'show' ]; then
		extra_args='-A'
	else
		echo; echo "${yellow}${bold}Warning: That wasn't a valid parameter, assuming hidden_files='hide'${reset}"
		unset $extra_args
	fi
}

function recovery(){
	if [ -n "$Device" ]; then
		if ! device_check; then exit 1; fi
	fi
	clear
	SV_PS3="$PS3"
	extra_args=''
	IFS=$(echo -en "\n\b")
	path="$BkPath"
	exit="false"
	while [ "$exit" = "false" ]; do
		clear
		list_format "$hidden_files"
		echo; echo "${green}Type 'h' to see available commands${reset}"
		PS3='Navigation Mode #$> '
		cd "$path"
		echo
		select npath in $(ls $extra_args -1); do
			if [ "$REPLY" = "r"  -o "$REPLY" = "R" ]; then
				clear
				PS3='Recovery Mode #$> '
				echo; echo "${green}Type 'h' to see available commands${reset}"; echo
				select recover in $(ls $extra_args -1); do
					if [ "$REPLY" = "n" -o "$REPLY" = "N" ]; then
						break
					elif [ "$REPLY" = "h" -o "$REPLY" = "H" ]; then
						available_commands
						echo; echo "${green}Type 'h' to see available commands${reset}"; echo
						unset $REPLY
					elif [ "$REPLY" = "q" -o "$REPLY" = "Q" ]; then
						exit="true"
						break
					elif [ "$REPLY" = "hide" -o "$REPLY" = "HIDE" ]; then
						hidden_files="hide"
						break
					elif [ "$REPLY" = "show" -o "$REPLY" = "SHOW" ]; then
						hidden_files="show"
						break
					elif [ -z $recover ]; then
						echo; echo "${red}${bold}That wasn't a valid choice${reset}"
						break
					else
						echo; read -p "In which folder do you want to save the recovered files/folders?[default:'$default_rescue']: " rescue_path
						if [ -z $rescue_path ]; then
							rescue_path="$default_rescue"
						fi
						if [ -d $rescue_path ]; then
							cp -Rv "$path/$npath/$recover" "$rescue_path"
							find "$rescue_path" -type f -exec chmod 666 "{}" \;
							find "$rescue_path" -type d -exec chmod 777 "{}" \;
						elif ! [ -d $rescue_path ]; then
							mkdir "$rescue_path"
							cp -Rv "$path/$npath/$recover" "$rescue_path"
							find "$rescue_path" -type f -exec chmod 666 "{}" \;
							find "$rescue_path" -type d -exec chmod 777 "{}" \;
						else
							echo; echo "${red}${bold}Error: $rescue_path already exists and is not a folder${reset}"
							break
						fi
					fi
				done
			elif [ "$REPLY" = ".." ]; then
				path="$path/.."
				break
			elif [ "$REPLY" = "q" -o "$REPLY" = "Q" ]; then
				exit="true"
				break
			elif [ "$REPLY" = "h" -o "$REPLY" = "H" ]; then
				available_commands
				unset $REPLY
			elif [ "$REPLY" = "hide" -o "$REPLY" = "HIDE" ]; then
				hidden_files="hide"
				break
			elif [ "$REPLY" = "show" -o "$REPLY" = "SHOW" ]; then
				hidden_files="show"
				break
			else
				if [ ! -d $npath ]; then
					echo; echo "${red}Error: that is not a directory, please, choose directories only"
					break
				else
					path="$path/$npath"
					break
				fi
			fi
			break
		done
	done
	cd
	if [ -n "$Device" ]; then
		umount -f "$Device"
	fi
}

function clean(){
	if [ -n "$Device" ]; then
		if ! device_check; then exit 1; fi
	fi
	date_today=$(date "+%s")
	find "$BkPath" -mindepth 1 | while read bfile
	do
		dfile=$(echo "$bfile" | sed "s|$BkPath|$DPath|")
		access_date=$(date -d $(stat -c %x "$bfile" | cut -d" " -f1) "+%s")
		# The '86400' is to transform seconds directly to days
		date_difference="$((($date_today-$access_date)/86400))"
		if [[ ! -e "$dfile" ]]; then
			if [[ "$date_difference" -ge "$days" ]]; then
				echo "${red}File $dfile not found and is $days days older in the backup so deleting from backup...${reset}"
				rm -rf "$bfile"
			fi
		else
		# This is to update the last access time on the file in the backup if the file wasn't removed, this way, we count the $days the file was in the backup since it was deleted,
		# not since it was created.
		# Note that normally, filesystems are loaded with the option relatime, which only updates the access time once per day, to avoid too much I/O operations because that will
		# cause the filesystem to be really slow
			if [[ ! -d "$bfile" ]]; then
				head -n1 "$bfile" 1>/dev/null 2>/dev/null
				continue
			else
				continue
			fi
		fi
	done
	if [ -n "$Device" ]; then
		umount -f "$Device"
	fi
}

function menu(){
	while true
	do
		clear
		echo "${bold}${green}###################################################################${reset}"
		echo
		echo "${bold}${blue}			WELCOME TO MYBACKUP MENU${cyan}"
		echo
		echo "1) Backup your files"
		echo "2) Open backup device to recover files"
		echo "3) Recovery Tool"
		echo "4) Clean older removed files"
		echo "5) Show info about backup device"
		echo "6) Exit"
		echo
		echo "${bold}${green}###################################################################${reset}"
		echo
		echo
		echo -n "${bold}${yellow}Choose: ${reset}"
		read choice

		case $choice in
			1) backup; continue ;;
			2) browse; continue ;;
			3) recovery; continue ;;
			4) clean; continue ;;
			5) infor ; echo ;read -p "${bold}${green}Type enter to return to menu" pause; continue ;;
			6) quit  ;;
			*) echo -ne "\n${red}Menu option is not correct, returning to menu${reset}";  sleep 2; continue ;;
		esac
	done
}

if [[ $EUID -ne 0 ]]; then echo "${red}You need root privileges to run this script!${reset}"
else
	if [[ $# -eq 0 ]]; then menu
	elif [[ $# -eq 1 ]]; then
		case $1 in
			-b|--backup) backup ;;
			-o|--open) open ;;
			-r|--recovery) recovery ;;
			-c|--clean) clean ;;
			-i|--info) infor ;;
			-h|--help) usage ;;
			*) echo "${red}Parameter error!${reset}"; echo; usage ;;
		esac
	else
		echo "${red}Parameter error!${reset}"
		usage
	fi
fi
exit 0
