#!/bin/bash

###########################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Version: 2.2.1-rc
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
###########################################################################################################

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
	if [[ -d /mnt/Backup/IT ]]; then umount /dev/sda1; fi
	exit 0
}

function backup(){
	if [[ ! -d /mnt/Backup/IT ]]; then mount /dev/sda1; fi
	cp -ru --no-preserve=all /mnt/Data/IT /mnt/Backup/
	cp -ru --no-preserve=all /mnt/Data/Music /mnt/Backup/
	find /mnt/Backup -type d -exec chmod -R 770 {} \;
	find /mnt/Backup -type f -exec chmod -R 660 {} \;
	umount /dev/sda1
	exit 0
}

function browse(){
	clear
	if [[ ! -d /mnt/Backup/IT ]]; then mount /dev/sda1; fi
	nautilus /mnt/Backup
	umount /dev/sda1
	exit 0
}

function recovery(){
	clear
	if [[ ! -d /mnt/Backup/IT ]]; then mount /dev/sda1; fi
	echo "Welcome to recovery tool"
	echo
	while true
	do
	      echo -n "Which folder/file do you want to recover: "
		read file
		find /mnt/Data/IT/programming/myrepo/bash_scripts/myBackup/testenv/testb -name $file -exec cp -i {} /mnt/Data/IT/programming/myrepo/bash_scripts/myBackup/testenv/testd \;
		echo -n "Continue recovering? (Y/n): "
		read choice
		if [ $choice == "\n" ] || [ $choice == "Y" ] || [ $choice == "y" ]; then continue
		elif [ $choice == "N" ] || [ $choice == "n" ]; then break
		else echo "Option not correct, assuming yes..." && continue
		fi
	done
}

function clean(){
	for bfile in `find /mnt/Backup/`
	do
		dfile=$(echo $bfile | sed 's/Backup/Data/')
		if [[ ! $(find /mnt/Data -wholename $dfile) ]]; then rm -rf $bfile; fi
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
	
	
	
	
	
	
	
	


