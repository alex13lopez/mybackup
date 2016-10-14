#!/bin/bash

###########################################################################################################
# Name: myBackup
# Author: ArenGamerZ
# Email: arendevel@gmail.com
# Description: This is a Backup program that will help you to maintain, adminstrate and make your backup.
###########################################################################################################

function usage(){
	clear
	echo """Usage: mbackup [OPTION]    
       OPTION:        
		--backup	--> 	Performs a backup and exits
		--clean	--> 	Performs a clean of older removed files and exits
		--browse	--> 	Browses the backup device with nautilus and exits
		--recovery	-->	Goes directly to recovery tool
		-h --help	-->	Shows this help"""

}

function backup(){
	clear
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
	while true:
	do
		echo -n "Which folder/file do you want to recover: "
		read file
		find /mnt/Backcup -name $file -exec cp -i {} \;
		echo -n "Continue recovering? (Y/n)"
		read choice
		if [[ $choice == \n ]] || [[ $choice == [Yy] ]]; then continue
		elif [[ $choice == [Nn] ]]; then break
		else echo "Option not correct, assuming yes..." && continue
		fi
	done
}

function clean(){
	for bfile in `find /mnt/Backup`
	do
		dfile=$(echo $bfile | sed 's/Backup/Data/')
		if [[ ! find /mnt/Data -name $dfile ]]; then rm -rf $bfile; fi
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

menu
