#!/bin/bash

#########################################
# Author : Markus Wildner              	#
# Created :	27.11.24		#
# Modified : 	27.11.24		#
#					#
# Description : 			#
# Ein monitoring System			#
# 					#
# Usage : 				#
# ./audit_system [-A] [-p]		#
# 					#
######################################### 											

clear

### Declaring variables ###
runAccountAudit="false"
runPermAudit="false"
reportDir="./Auditreports"
reportPref="Accountaudit_"
reportPermPref="Permaudit_"

### Checking if reportDir is present ###

if [ -d "$reportDir" ]
then
	echo "Report directory already exists, moving forward..."
else	
 	mkdir "./Auditreports"
fi 

### Checking if there where command arguments given ###

while getopts :Aph opts
do
	case "$opts" in
		A) runAccountAudit="true";;
		p) runPermAudit="true";;
		h) echo -e "Possible Arguments are:\n[A] = enable Accountaudit\n[p] = enable Permissionaudit\n[h] = This helptext\n\nExit Programm.. "
		exit 0;;
		*) echo -e "Wrong args given, possible Arguments are -A -p or -Ap.\nSelect -h for help\nExit Programm.. "
		   exit 1;;	
	esac
done

### Check if no arguments present ###

if [ $OPTIND -eq 1 ]
then
	# no Arguments given so set all switches to true:
	runAccountAudit="true"
	runPermAudit="true"
fi

### Now run the desired commands, checking if command is set to true ###

### Accountaudit ###

if [ "$runAccountAudit" = "true" ]
then
	echo
	echo -e "\t******************************"
	echo -e "\t**** Running Accountaudit ****"
	echo -e "\t******************************"
	echo

	### Determine amount of current false/nologin shells
	echo -e "Number of current false or nologin shells:"
	reportDate="$(date +%F_%s)"
	accountReport="$reportDir/$reportPref$reportDate.rpt"

	### Create current Report ###
	## 1. With cat pipe contents of /etc/passwd into cut command (-d = delimter here :) also (-f7 use the field nr 7)
	## 2. From this result grep only contents they are including false or nologin
	## 3. Use the wc command to get the amount of lines
	## 4. With the tee command write the result into given file and also to stdout console

	cat /etc/passwd | cut -d: -f7 |  grep -E "(false|nologin)" | wc -l | tee "$accountReport"

	### For security reasons make the writen report immutable ###

	sudo chattr -i "$accountReport"

	### In order to detect changes to older report results show them ###
	## 1. Get all existing Reportnames in Dir using the ls command the -t1 arg brings the result in 1 column
	## 2. So now we can select with the sed command the second (2p) result in the given column the -n suppress any output 
       	## Hint: because in the ls -t1 command the previous file is listed under the newest file, this seems to work 
	prevReport="$(ls -t1 $reportDir/$reportPref*.rpt | sed -n '2p')"

	if [ -z "$prevReport" ]
	then
		echo -e "No previous report where found.\nNo compare for older false or nologin shells possible."
	else
		echo -e "Amount of previous false or nologin shells:"
		cat "$prevReport"

		if [ $(cat $prevReport) = $(cat $accountReport) ]
		then
			echo
			echo -e "\t############# Programme hint ####################"
			echo -e "\tIt look like nothing is changed, since last run"
			echo -e "\t#################################################"
			echo
		else
			echo
			echo -e  "\t############ Programme hint ####################################"
			echo -e  "\tThere are differences, maybe you have to investigate this issue?"
			echo -e  "\t################################################################"
			echo
		fi
	fi
fi

### Permssionaudit ###

if [ "$runPermAudit" = "true" ]
then
	echo 
	echo -e "\t******************************"	
	echo -e "\t*** Running Permmisonaudit ***"
	echo -e "\t******************************"
	
	permReport="$reportDir/$reportPermPref$(date +%F_%s).rpt"

	### Create the report ###
	echo
	echo -e "\tCreating the report for permissions, this may take a while"

	sudo  find / -perm /6000 > $permReport 2> /dev/null
	sudo chattr -i $permReport
	
	echo -e "\tFinished creating actual permission report"

	### checking difference between pervious reports

	prevReport="$(ls -1t $reportDir/$reportPermPref*.rpt | sed -n '2p')"

	echo -e "Actualreportname: $permReport"
	echo -e "Previous Reportname: $prevReport"

	if [ -z "$prevReport" ]
	then
		echo -e "No previos report for permission audit given.\nNo difference check possible."
	else
		echo
		echo -e "Checking difference between previous results in case of permission: "

		differences=$( diff $permReport $prevReport)

		if [ -z "$differences" ]
		then
			echo -e "No differences found"
		else
			echo -e $differences
		
		fi
	fi



fi




