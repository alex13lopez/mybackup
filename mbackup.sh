#!/bin/bash

###########################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Version: 2.5.2b
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
# Important: Set the vars below to suit your configuration, these are just an example.
###########################################################################################################

BkPath=/mnt/Backup # This is the path where the backup will be stored
BFolder=Backup # This is the name of the mountpoint where your Backup is stored
DPath=/mnt/Data # This is the path where the data to be backuped will be taken from
DFolder=Data # This is the name of the mountpoint where your Data is stored
DtoBackup=('/mnt/Data/IT/' '/mnt/Data/Music/') # Put the folders you want to backup between '' and separated by spaces
Device=/dev/sda1 # This is the device where the backup is stored

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
		<noargs>	-->	Goes to main menu
		--backup	--> 	Performs a backup and exits
		--clean		--> 	Performs a clean of older removed files and exits
		--browse	--> 	Browses the backup device with nautilus and exits
		--recovery	-->	Goes directly to recovery tool
		-h --help	-->	Shows this help"""

}

function quit(){
	if df | grep -q $Device; then umount -f $Device; fi
	exit 0
}

function backup(){
	if ! df | grep -q $Device; then mount $Device $BkPath; fi
	for dir in ${DtoBackup[@]} 
	do
		cp -ruv --no-preserve=all $dir $BkPath
	done
	find $BkPath -type d -exec chmod -R 770 {} \;
	find $BkPath -type f -exec chmod -R 660 {} \;
	umount -f $Device
}

function browse(){
	clear
	if ! df | grep -q $Device; then mount $Device $BkPath; fi
	nautilus $BkPath & > /dev/null
	echo "${bold}${green}Type enter when you finished...${reset}"
	read pause
	nautilus -q
	umount -f $Device
}

function recovery(){
	clear
	if ! df | grep -q $Device; then mount $Device $BkPath; fi
	if [ ! -d $DPath/recovered ]; then mkdir $DPath/recovered; fi
	echo "${bold}${blue}Welcome to recovery tool${reset}"
	echo
	while true
	do
	    echo -n "${bold}${green}Which folder/file do you want to recover: ${reset}"
		read name
		if [[ $name == "!quit" ]]; then
			break
		else
			file=$(find "$BkPath" -name "$name")
			if [ -f "$file" ]; then
				echo "${bold}${cyan}Is $file the file/folder you want to recover?(Y/n) ${reset}"
				read choice
				if [ ! $choice ] || [ $choice == "Y" ] || [ $choice == "y" ]; then cp -ri $file $DPath/recovered
				elif [ $choice == "N" ] || [ $choice == "n" ]; then continue
				else echo "${bold}${yellow}Assuming yes...${reset}"; cp -ri $file $DPath/recovered
				fi
				echo -n "${bold}${green}Continue recovering? (Y/n): ${reset}"
				read choice
				if [ ! $choice ] || [ $choice == "Y" ] || [ $choice == "y" ]; then continue
				elif [ $choice == "N" ] || [ $choice == "n" ]; then break
				else echo "${bold}${yellow}Assuming yes...${reset}"; continue
				fi
			elif [ ! -f "$file" ]; then
				echo "${red} File $file not found, make sure you wrote it correctly${reset}"
				continue
			else
				echo "${red}You didn't write anything! (Use !quit to exit)${reset}"
				continue
			fi
		fi
	done
	umount -f $Device
}

function clean(){
	if ! df | grep -q $Device; then mount $Device $BkPath; fi
	find "$BkPath" -mindepth 1 | while read bfile
	do
	dfile=$(echo "$bfile" | sed "s/$BFolder/$DFolder/")
	if [[ ! -e "$dfile" ]]; then
		echo "${red}File $dfile not found, deleting from backup...${reset}"
		rm -rf "$bfile"
	else
		continue
	fi
	done
	umount -f $Device
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
		echo "2) Browse backup device to recover files"
		echo "3) Recovery Tool"                                      
		echo "4) Clean older removed files"
		echo "5) Exit"
		echo
		echo "${bold}${green}###################################################################${reset}"
		echo
		echo
		echo -n "${bold}${yellow}Choose: ${reset}"
		read choice

		case $choice in
			1) backup ;;
			2) browse ;;
			3) recovery ;;
			4) clean ;;
			5) quit ;;
			*) echo -ne "\n${red}Menu option is not correct, returning to menu${reset}";  sleep 2; continue ;;
		esac
	done
}

if [[ $EUID -ne 0 ]]; then echo "${red}GTFO! You need root privileges!${reset}"
else
	if [[ $# -eq 0 ]]; then menu
	elif [[ $# -eq 1 ]]; then
		case $1 in
			--backup) backup ;;
			--browse) browse ;;
			--recovery) recovery ;;
			--clean) clean ;;
			-h|--help) usage ;;
			*) echo "${red}Parameter error!${reset}"; echo; usage ;;
		esac
	else
		echo "${red}Parameter error!${reset}"
		usage
	fi
fi
exit 0
