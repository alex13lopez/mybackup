#!/bin/bash

###########################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Version: 3.0b
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
# Important: Set the vars below to suit your configuration, these are just an example.
###########################################################################################################


BkPath=/mnt/Backup		                         # Full path where the backup will be stored
DPath=/mnt/Data    	                             # Full path of the location of your root data folder
DtoBackup=('/mnt/Data/IT/' '/mnt/Data/Music/')   # Specific directorys to backup, separated by spaces
Device=/dev/sda1                           		 # Device of the backup. Use only if you want automatic mount and umount, leave empty otherwise.

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
	if [ -n $Device ]; then
		if df | grep -q $Device; then umount -f $Device; fi
	fi
	exit 0
}

function infor(){
	if [ -n $Device ]; then
		if ! df | grep -q $Device; then mount $Device $BkPath; fi
	fi
	df -h | head -n 1
	df -h | grep $Device
	if [ -n $Device ]; then
		umount -f $Device
	fi
}

function backup(){
	if [ -n $Device ]; then
		if ! df | grep -q $Device; then mount $Device $BkPath; fi
	fi
	for dir in ${DtoBackup[@]} 
	do
		cp -ruv --no-preserve=all $dir $BkPath
	done
	find $BkPath -type d -exec chmod -R 770 {} \;
	find $BkPath -type f -exec chmod -R 660 {} \;
	if [ -n $Device ]; then
		umount -f $Device
	fi
}

function open(){
	clear
	if [ -n $Device ]; then
		if ! df | grep -q $Device; then mount $Device $BkPath; fi
	fi
	nautilus $BkPath & > /dev/null
	echo "${bold}${green}Type enter when you finished...${reset}"
	read pause
	nautilus -q
	if [ -n $Device ]; then
		umount -f $Device
	fi
}

function recovery(){
	clear
	if [ -n $Device ]; then
		if ! df | grep -q $Device; then mount $Device $BkPath; fi
	fi
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
	if [ -n $Device ]; then
		umount -f $Device
	fi
}

function clean(){
	if [ -n $Device ]; then
		if ! df | grep -q $Device; then mount $Device $BkPath; fi
	fi
	find "$BkPath" -mindepth 1 | while read bfile
	do
	dfile=$(echo "$bfile" | sed "s|$BkPath|$DPath|")
	if [[ ! -e "$dfile" ]]; then
		echo "${red}File $dfile not found, deleting from backup...${reset}"
		rm -rf "$bfile"
	else
		continue
	fi

	

	done
	if [ -n $Device ]; then
		umount -f $Device
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
			5) infor ; read -p "${bold}${green}Type enter to return to menu" pause; continue ;;
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
