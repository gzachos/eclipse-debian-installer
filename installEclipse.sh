#!/usr/bin/env bash

#+-----------------------------------------------------------------------+
#|               Copyright (C) 2015-2018 George Z. Zachos                |
#+-----------------------------------------------------------------------+
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Contact Information:
# Name: George Z. Zachos
# Email: gzzachos_at_gmail.com


# Run the script with the following command to
# view the program's exit code:
#       $ sudo ./installEclipse.sh; echo "exit code: $?";
# Note that in UNIX-like systems, the exit code is represented as an 8-bit unsigned(!) char [1-255].


# Print error ${2} and exit with ${1} as an exit code.
perror_exit () {
	echo -e "\n***ERROR***"
	echo -e "${2}"
	echo -e "Script will now exit.\n"
#	echo -e "\n##################################################################################"
#	echo -e   "#                      The installation was NOT successful!                      #"
#	echo -e   "##################################################################################\n"
	exit ${1}
}


# An initial message is printed to console.
echo "##################################################################################"
echo "#               ***  You are about to install Eclipse IDE ***                    #"
echo "#                                                                                #"
echo "# First, download the preferred version of Eclipse and save the '.tar.gz' file   #"
echo "# inside the 'Downloads' directory of your home directory. Then execute this     #"
echo "# script from any directory you want via the command below:                      #"
echo "#        sudo ./installEclipse.sh                                                #"
echo "#                 (Make sure the script exists inside your current directory!)   #"
echo "#                                                                                #"
echo "# In case you started downloading Eclipse after executing this script,           #"
echo "# wait until download is complete and then provide your username!!!              #"
echo "#                                                                                #"
echo "#         NOTE: You can override the default directory option by providing the   #"
echo "#               (absolute) path of the directory containing the '.tar.gz' file   #"
echo "#               as a command line argument!                                      #"
echo "#                                                                                #"
echo "#               *** For more information refer to README.md ***                  #"
echo "##################################################################################"

# If no command line argument is provided.
if [ -z "${1}" ]
then
	# Prompt user to provide a username.
	# The script is executed as root, so 'whoami' may be invalid.
	echo -ne "Enter your username(<username>@<host>) and press [ENTER]:\n > "
	read USERNAME

	# Check if $USERNAME is empty.
	if [ -z "${USERNAME}" ]
	then
		perror_exit 1  "Username is empty."
	fi

	# $DIRPATH gets the absolute path of the user's 'Downloads' directory assigned.
	DIRPATH="/home/${USERNAME}/Downloads/"
else
	# $DIRPATH is assigned the absolute path given as a command line argument.
	DIRPATH="${1}"
	# Check if $DIRPATH is an absolute path.
	if [ "${DIRPATH:0:1}" != "/" ]
	then
		perror_exit 2 "${DIRPATH}: Should be an absolute path."
	fi
	# Append a trailing "/" if needed.
	if [ "{DIRPATH:(-1)}" != "/" ]
	then
		DIRPATH="${DIRPATH}/"
	fi
fi

# Check if $DIRPATH is a valid directory.
if [ ! -d "${DIRPATH}" ]
then
	perror_exit 3 "${DIRPATH}: Not a valid directory."
fi

# $FILES holds all the filenames inside $DIRPATH directory that begin with
# 'eclipse-' and end with '.tar.gz'.
FILES=$(sudo ls -1 ${DIRPATH} | grep ^eclipse- | grep .tar.gz$ | tr "\n" "\n")

# Check if there are any filenames complying with the previous checks.
if [ -z "${FILES}" ]
then
	perror_exit 4 "There is no '.tar.gz' file associated with Eclipse IDE inside ${DIRPATH}."
fi

# $FILENUM holds the number of files held in $FILES
FILENUM=$(echo ${FILES} | wc -w)

# If there are more than one files, prompt user to choose one.
if [ ${FILENUM} -gt 1 ]
then
	# The existing files inside $DIRPATH directory are printed one every single line,
	# including a number/index at the beginning of each line.
	echo -e "\nThe following files were found inside ${DIRPATH}:"
	INDEX=0
	for file in ${FILES}
	do
		echo "[${INDEX}] ${file}"
		INDEX=$((INDEX+1))
	done
	# Prompt user to enter the number/index of the file to be installed.
	echo -ne "\nEnter the number/index of the file you want to be installed (0-$((INDEX-1))) and press [ENTER]:\n > "
	read CHOICE
	# if $CHOICE holds a valid number/index, the related filename is assigned to $FILE.
	if [ ${CHOICE} -lt 0 ] || [ ${CHOICE} -ge ${INDEX} ]
	then
		perror_exit 5 "Invalid choice!"
	fi
	INDEX=0
	for file in ${FILES}
	do
		if [ ${CHOICE} -eq ${INDEX} ]
		then
			FILE=${file}
			break
		fi
		INDEX=$((INDEX+1))
	done
	echo -e "\nChosen file: ${file}\n"
	sleep 3
else
	# If $FILES holds only one filename, it's value is assigned to $FILE.
	FILE=${FILES}
fi

# $TYPE holds the type of the file held in $FILE
TYPE="$(file -b ${DIRPATH}${FILE})"

# Check if the type of $FILE matches "gzip".
if  [ "${TYPE:0:4}" != "gzip" ]
then
	perror_exit 6 "There is no '.tar.gz.' file associated with Eclipse IDE inside ${DIRPATH}."
fi

# If execution reaches this point of the script, it means that there is a valid eclipse '.tar.gz'
# file inside $DIRPATH. The following part of the script is the one that conducts the installation.

# Extract the 'tar.gz' file in the current directory.
if ! sudo tar -zxvf "${DIRPATH}${FILE}"
then
	perror_exit 7 "Problem extracting \"${DIRPATH}${FILE}\""
fi

# Move the 'eclipse' directory created from the extraction above to /opt/
if ! sudo mv ./eclipse/ /opt/
then
	perror_exit 8 "Unable to move `pwd`/eclipse/ in /opt/"
fi

# The 'eclipse.desktop' file is created
distinfo="$(uname -a)"
if [ "${distinfo#*Ubuntu}" == "${distinfo}" ]
then
	exe="Exec=/opt/eclipse/eclipse"
else
	# The following line solves rendering issues on Ubuntu-based distributions
	exe="Exec=env UBUNTU_MENUPROXY=0 SWT_GTK3=0 /opt/eclipse/eclipse"
fi

if ! sudo echo -e "[Desktop Entry]\nName=Eclipse\nType=Application\n${exe}\nTerminal=false\nIcon=/usr/share/pixmaps/eclipse.xpm\nComment=Intergrated Development Environment\nNoDisplay=false\nCategories=Development;" > eclipse.desktop
then
	perror_exit 9 "Error creating desktop file"
fi

# The desktop file is installed and then deleted.
if ! sudo desktop-file-install eclipse.desktop
then
	perror_exit 10 "Error installing desktop file"
fi

if ! sudo rm -f eclipse.desktop
then
	perror_exit 11 "Error removing temporary desktop file"
fi

# A soft link of eclipse's executable file is created in /usr/local/bin/eclipse.
if ! sudo ln -s /opt/eclipse/eclipse /usr/local/bin/eclipse
then
	perror_exit 12 "Cannot create soft link /usr/local/bin/eclipse [target: /opt/eclipse/eclipse]"
fi

# Eclipse's 'icon.xpm' is copied to /usr/share/pixmaps/ and renamed to 'eclipse.xpm'
if ! sudo cp /opt/eclipse/icon.xpm /usr/share/pixmaps/eclipse.xpm
then
	perror_exit 13 "Error installing XPM file in /usr/share/pixmaps/"
fi

echo -e "\n##################################################################################"
echo -e   "#                        The installation was successful!                        #"
echo -e   "##################################################################################\n"

