#!/bin/bash

###########################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Version: 2.3.0a
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
###########################################################################################################

BkPath=/mnt/Backup # This is the path where the backup will be stored
BFolder=Backup # This is the name of the mountpoint where your Backup is stored
DPath=/mnt/Data # This is the path where the data to be backuped will be taken from
DFolder=Data # This is the name of the mountpoint where your Data is stored
DtoBackup=('/mnt/Data/IT' '/mnt/Data/Music') # Put the folders you want to backup between '' and separated by spaces
Device=/dev/sda1 # This is the device where the backup is stored

function usage(){
	echo """Usage: mbackup <OPTION>    
       OPTION:        
		--backup	--> 	Performs a backup and exits
		--clean		--> 	Performs a clean of older removed files and exits
		--browse	--> 	Browses the backup device with nautilus and exits
		--recovery	-->	Goes directly to recovery tool
		<noargs>	-->	Goes to main menu
		-h --help	-->	Shows this help"""

}

function quit(){
	if ls $BkPath; then umount -f $Device; fi
	exit 0
}

function backup(){
	if ! ls $BkPath; then mount $Device; fi
	for dir in ${DtoBackup[@]} 
	do
		cp -ruv --no-preserve=all $dir $BkPath
	done
	find $BkPath -type d -exec chmod -R 770 {} \;
	find $BkPath -type f -exec chmod -R 660 {} \;
	umount $Device
	exit 0
}

function browse(){
	clear
	if ! ls $BkPath; then mount $Device; fi
	nautilus $BkPath
	echo "Type enter when you finished..."
	read pause
	ps aux | grep nautilus | tr -s ' ' | cut -d' ' -f2 | while read i; do kill -9 $i; done
	umount -f $Device
	exit 0
}

function recovery(){
	clear
	if ! ls $BkPath; then mount $Device; fi
	if [ ! -d $DPath/recovered ]; then mkdir $DPath/recovered; fi
	echo "Welcome to recovery tool"
	echo
	while true
	do
	    echo -n "Which folder/file do you want to recover: "
		read name
		file=$(find $BkPath -name $name)
		if $file; then
			echo "Is $file the file/folder you want to recover?(Y/n)"
			read choice
			if [ $choice == "\n" ] || [ $choice == "Y" ] || [ $choice == "y" ]; then cp -ri $file $DPath/recovered
			elif [ $choice == "N" ] || [ $choice == "n" ]; then continue
			else echo "Assuming yes..." && continue 
			fi
		echo -n "Continue recovering? (Y/n): "
		read choice
		if [ $choice == "\n" ] || [ $choice == "Y" ] || [ $choice == "y" ]; then continue
		elif [ $choice == "N" ] || [ $choice == "n" ]; then break
		else echo "Assuming yes..." && continue
		fi
	done
}

function clean(){
	for bfile in `find $BkPath`
	do
		dfile=$(echo $bfile | sed "s/$BFolder/$DFolder/")
		if ! find $DPath -wholename $dfile; then rm -rf $bfile; fi
	done
}

function menu(){
	clear
	echo "###################################################################"
	echo
	echo "1) Backup your files"
	echo "2) Browse backup device to recover files"
	echo "3) Recovery Tool"
	echo "4) Clean older removed files"
	echo "5) Exit"
	echo
	echo "###################################################################"
	echo
	echo
	echo -n "Choose: "
	read choice

	case $choice in
		1) backup ;;
		2) browse ;;
		3) recovery ;;
		4) clean ;;
		5) quit ;;
		*) echo "Menu option is not correct, returning to menu" && menu ;;
	esac
}

if [[ $EUID -ne 0 ]]; then echo "GTFO! You need root privileges!"
else
	if [[ $# -eq 0 ]]; then menu
	elif [[ $# -eq 1 ]]; then
		case $1 in
			--backup) backup ;;
			--browse) browse ;;
			--recovery) recovery ;;
			--clean) clean ;;
			*) echo "Parameter error!" && echo && usage ;;
		esac
	else
		echo "Parameter error!"
		usage
	fi
fi
exit 0
	
	
	
	
	
	
	
	


