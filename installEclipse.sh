#!/bin/sh

#+-----------------------------------------------------------------------+
#|               Copyright (C) 2015-2016 George Z. Zachos                |
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
	echo -n "Enter your username(<username>@<host>) and press [ENTER]:\n > "
	read USERNAME

	# Check if $USERNAME is empty.
	if [ -z "${USERNAME}" ]
	then
		echo  "\n***ERROR***\nUsername is empty.\nScript will now exit.\n"
		exit 1
	fi

	# $DIRPATH gets the absolute path of the user's 'Downloads' directory assigned.
	DIRPATH="/home/${USERNAME}/Downloads/"
else
	# $DIRPATH is assigned the absolute path given as a command line argument.
	DIRPATH=${1}
	# Check if $DIRPATH ends with a forward slash.
	last_char=$(echo ${DIRPATH} | tail -c 2)
	if [ "${last_char}" != "/" ]
	then
		echo "\n***ERROR***\n${DIRPATH}: Path should end with a '/'.\nScript will now exit.\n"
		exit 2
	fi
fi

# Check if $DIRPATH is a valid directory.
if [ ! -d "${DIRPATH}" ]
then
	echo "\n***ERROR***\n${DIRPATH}: Not a valid directory.\nScript will now exit.\n"
	exit 3
fi

# $FILES holds all the filenames inside $DIRPATH directory that begin with 'eclipse-' and end with '.tar.gz'.
FILES=$(sudo ls -1 ${DIRPATH} | grep ^eclipse- | grep .tar.gz$ | tr "\n" "\n")

# Check if there are any filenames complying with the previous checks.
if [ -z "${FILES}" ]
then
	echo  "\n***ERROR***\nThere is no '.tar.gz' file associated with Eclipse IDE inside ${DIRPATH} directory.\nScript will now exit.\n"
	exit 4
fi

# $FILENUM holds the number of files held in $FILES
FILENUM=$(echo $FILES | wc -c)

# If there are more than one files, prompt user to choose one.
if [ ${FILENUM} -gt 1 ]
then
	# The existing files inside $DIRPATH directory are printed one every single line,
	# including a number/index at the beginning of each line.
	echo "\nThe following files were found inside \"${DIRPATH}\" directory:"
	INDEX=0
	for file in ${FILES}
	do
		echo "[${INDEX}] ${file}"
		INDEX=$((INDEX+1))
	done
	# Prompt user to enter the number/index of the file to be installed.
	echo -n "\nEnter the number/index of the file you want to be installed (0-$((INDEX-1))) and press [ENTER]:\n > "
	read CHOICE
	# if $CHOICE holds a valid number/index, the related filename is assigned to $FILE.
	if [ ${CHOICE} -lt 0 ] || [ ${CHOICE} -ge ${INDEX} ]
	then
		echo  "\n***ERROR***\nInvalid choice!\nScript will now exit.\n"
		exit 5
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
	echo "\nChosen file: ${file}\n"
	sleep 3
else
	# If $FILES holds only one filename, it's value is assigned to $FILE.
	FILE=${FILES}
fi

# $TYPE holds the type of the file held in $FILE
TYPE="$(file -b ${DIRPATH}${FILE} | awk '{print $1}')"

# Check if the type of $FILE matches "gzip".
if  [ "${TYPE}" != "gzip" ]
then
	echo "\n***ERROR***\nThere is no '.tar.gz.' file associated with Eclipse IDE inside ${DIRPATH} directory.\nScript will now exit.\n"
	exit 6
fi

# If execution reaches this point of the script, it means that there is a valid eclipse '.tar.gz'
# file inside $DIRPATH. The following part of the script is the one that conducts the installation.

# Extract the 'tar.gz' file in the current directory.
sudo tar -zxvf ${DIRPATH}${FILE}
X1="$?"

# Move the 'eclipse' directory created from the extraction above to /opt/
sudo mv ./eclipse/ /opt/
X2="$?"

# The 'eclipse.desktop' file is created
sudo echo -e "[Desktop Entry]\nName=Eclipse\nType=Application\nExec=/opt/eclipse/eclipse\nTerminal=false\nIcon=/usr/share/pixmaps/eclipse.xpm\nComment=Intergrated Development Environment\nNoDisplay=false\nCategories=Development;" > eclipse.desktop
X3="$?"

# The '.desktop' file is installed and then deleted.
sudo desktop-file-install eclipse.desktop
X4="$?"

sudo rm -rf eclipse.desktop
X5="$?"

# A soft link of eclipse's executable file is created in /usr/local/bin/eclipse.
sudo ln -s /opt/eclipse/eclipse /usr/local/bin/eclipse
X6="$?"

# Eclipse's 'icon.xpm' is copied to /usr/share/pixmaps/ and renamed to 'eclipse.xpm'
sudo cp /opt/eclipse/icon.xpm /usr/share/pixmaps/eclipse.xpm
X7="$?"

# The exit code of each command is assigned to the variable $X1 to $X7.
# If there are no errors, each exit code equals to "0". The sum of all exit codes is assigned to $SUM.
SUM=$((X1+X2+X3+X4+X5+X6+X7))

# Finally, feedback about the installation status is given to the user according to the value of $SUM.
# Note that in UNIX-like systems, the exit code is represented as an 8-bit unsigned(!) char [1-255].
if [ "${SUM}" -eq "0" ]
then
	echo "\n##################################################################################"
	echo   "#                        The installation was successful!                        #"
	echo   "##################################################################################\n"
	exit 0
else
	echo "\n##################################################################################"
	echo   "#                      The installation was NOT successful!                      #"
	echo   "##################################################################################\n"
	exit 7
fi

