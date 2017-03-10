#!/bin/bash

###########################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Version: 4.0.4-alpha
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
# Important: Set the vars below to suit your configuration.
# More IMPORTANT: This script is in BETA version, so report any bugs to me please
# Note: It's not mandatory to have the backup separated in another partition, but It is highly recommended,
#	    because if a ransomware ciphers your disk it will also cipher your backup, thus the
#	    purpose of having a backup will become useless.
###########################################################################################################

################################################ CONF VARS ######################################################################
# Full path where the backup will be stored
# IMPORTANT NOTE: Do not add a trailing '/' e.g: /mnt/backup instead of /mnt/backup/
BkPath=''
# Full path of the location of your root data folder
# IMPORTANT NOTE: Do not add a trailing '/' e.g: /home/aren instead of /home/aren/
DPath=''
# Specific directorys to backup, separated by spaces (and full path)
DtoBackup=('')
# Device of the backup. Use only if you want automatic mount and umount, leave empty otherwise.
Device=''
Automount='yes' #Default value: yes. Choose between 'yes' or 'no'.
# Days that files will be keeped in the backup if they were removed from data folder. Recommended days='30'
days=''
# Default folder when recovered files/folders will be restored
default_rescue="$DPath/rescued"
# Should hidden files and folders be shown in recovery CLI?
# Default option is 'hide'. You can choose either 'hide' or 'show'.
hidden_files='hide'
#################################################################################################################################

#Colors
red=`tput setaf 1`
yellow=`tput setaf 3`
blackback=`tput setab 0`
reset=`tput sgr0`
blue=`tput setaf 4`
cyan=`tput setaf 6`
bold=`tput bold`
green=`tput setaf 2`

function usage(){
	echo """Usage: mbackup <OPTION>
       OPTION:
		<noargs>      -->  Goes to main menu
		-b --backup   -->  Performs a backup and exits
		-c --clean    -->  Performs a clean of older removed files and exits
		-o --open     -->  Opens the backup device with nautilus and exits
		-r --recovery -->  Goes directly to recovery tool
		-i --info     -->  Shows info about the backup device
		-h --help     -->  Shows this help"""

}

function quit(){
	if [ -n "$Device" ]; then
		if df | grep -q "$Device"; then umount -f "$Device"; fi
	fi
	exit 0
}

function infor(){
	if [ -n "$Device" ]; then
		if ! df | grep -q "$Device"; then mount "$Device" "$BkPath"; fi
	fi
	df -h | head -n 1
	df -h | grep "$Device"
	if [ -n "$Device" ]; then
		umount -f "$Device"
	fi
}

function backup(){
	if [ -n "$Device" ]; then
		if ! df | grep -q "$Device"; then mount "$Device" "$BkPath"; fi
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
	clear
	if [ -n "$Device" ]; then
		if ! df | grep -q "$Device"; then mount "$Device" "$BkPath"; fi
	fi
	nautilus "$BkPath" & > /dev/null
	echo "${bold}${green}Type enter when you finished...${reset}"
	read pause
	nautilus -q
	if [ -n "$Device" ]; then
		umount -f "$Device"
	fi
}

function recovery(){
	clear
	SV_PS3="$PS3"
	IFS=$(echo -en "\n\b")
	if [ -n "$Device" ]; then
		if ! df | grep -q "$Device"; then mount "$Device" "$BkPath"; fi
	fi
	path="$BkPath"
	exit="false"
	echo; echo "Type 'r' when you see the file/folder you want to enter recovery mode"; echo "Type '..' to return to the previous folder"; echo "Type 'q' to quit"
	while [ "$exit" = "false" ]; do
		PS3='Navigation Mode #$> '
		cd "$path"
		echo
		select npath in $(ls -1); do
			if [ "$REPLY" = "r"  -o "$REPLY" = "R" ]; then
				PS3='Recovery Mode #$> '
				echo; echo "Type 'n' if you want to return to navigation mode"; echo
				select recover in $(ls -1); do
					if [ "$REPLY" = "n" -o "$REPLY" = "N" ]; then
						break
					elif [ -z $recover ]; then
						echo; echo "That wasn't a valid choice"
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
							echo; echo "Error: $rescue_path already exists and is not a folder"
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
			else
				path="$path/$npath"
				break
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
		if ! df | grep -q "$Device"; then mount "$Device" "$BkPath"; fi
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

if [[ $EUID -ne 0 ]]; then echo "${red}GTFO! You need root privileges!${reset}"
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
