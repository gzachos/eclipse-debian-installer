#!/bin/sh

#+-----------------------------------------------------------------------+
#|                  Copyright (C) 2015 George Z. Zachos                  |
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
# 	$ sudo ./installEclipse.sh; echo "exit code: $?";


# An initial message is printed to console.
echo "##################################################################################\n#\t\t***  You are about to install Eclipse IDE  ***\t\t\t #\n#\t\t\t\t\t\t\t\t\t\t #\n# First, download the preferred version of Eclipse and save the \".tar.gz\" file\t #\n# inside the \"Downloads\" directory of your home directory. You can run this\t #\n# script in any directory you want by the command below:\t\t\t #\n#\tsudo ./installEclipse.sh \t\t\t\t\t\t #\n#\t\t\t(Make sure it is inside your current directory!)\t #\n#\t\t\t\t\t\t\t\t\t\t #\n# Wait until download is complete and then provide your username!!!\t\t #\n#\t\t\t\t\t\t\t\t\t\t #\n#\t NOTE: If you want, you can give the absolute path of the directory\t #\n#\t\twhere the \".tar.gz\" file is saved, as a command line argument!   #\n#\t\t\t\t\t\t\t\t\t\t #\n#\t\t*** For more information refer to README.md ***\t\t\t #\n##################################################################################\n"


# If no command line argument is provided.
if [ -z "${1}" ]
then
	# The username inside whose 'Downloads' directory the eclipse 'tar.gz' file is saved,
	# is requested as an input from the user and it is saved in $USERNAME.
	echo -n "Enter your username(<username>@<host>) and press [ENTER]:\n > "
	read USERNAME

	# If $USERNAME is empty, the script exits with an exit code of "1".
	if [ -z "${USERNAME}" ]
	then
		echo  "\n***ERROR***\nUsername is empty.\nScript will now exit.\n"
		exit 1
	fi

	# $FILEPATH gets the absolute path of the user's 'Downloads' directory assigned.
	# (user is specified by $USERNAME)
	FILEPATH="/home/${USERNAME}/Downloads/"
else
# On the opposite case, $FILEPATH is assigned the absolute path given as a command line argument.
	FILEPATH=${1}
fi

# If $FILEPATH is not a valid directory, the script exits with an exit code of "2".
if [ ! -d "${FILEPATH}" ]
then
	echo  "\n***ERROR***\n${FILEPATH}: Not a valid directory.\nScript will now exit.\n"
	exit 2
fi

# $FILENAMES holds all the filenames inside $FILEPATH directory that begin with 'eclipse-' and end with '.tar.gz'.
FILENAMES=$(sudo ls -l ${FILEPATH} | awk '{print $9}' | grep ^eclipse- | grep .tar.gz$ | tr "\n" "\n")

# If there are no filenames complying with the previews checks, the value of $FILENAMES is emtpy and
# the script exits with an exit code of "3".
if [ -z "${FILENAMES}" ]
then
	echo  "\n***ERROR***\nThere is no '.tar.gz' file associated with Eclipse IDE inside ${FILEPATH} directory.\nScript will now exit.\n"
	exit 3
fi

# $FILENUM holds the number of files held in $FILENAMES
FILENUM=0
for x in ${FILENAMES}
do
	FILENUM=$((FILENUM+1))
done

# If there are more than one files, user is prompted to choose one.
if [ "${FILENUM}" -gt "1" ]
then
	# The existing files inside ${FILEPATH} directory are printed one every single line,
	# including a number/index at the beginning of each line.
	echo "\nThe following files were found inside \"${FILEPATH}\" directory:"
	INDEX=0
	for x in ${FILENAMES}
	do
		echo "[${INDEX}] ${x}"
		INDEX=$((INDEX+1))
	done
	# Then the user is prompted to enter the number/index of the file that wants to be installed.
	echo -n "\nEnter the number/index of the file you want to be installed (0-$((INDEX-1))) and press [ENTER]:\n > "
	read CHOICE
	# if $CHOICE holds a valid number/index, the related filename is assigned to $FILE.
	# On the opposite case, the script exits with an exit code of "4".
	if [ "${CHOICE}" -ge "0" ] && [ "${CHOICE}" -lt "${INDEX}" ]
	then
		continue
	else
		echo  "\n***ERROR***\nInvalid choice!\nScript will now exit.\n"
		exit 4
	fi
	INDEX=0
	for x in ${FILENAMES}
	do
		if [ "${CHOICE}" -eq "${INDEX}" ]
		then
			FILE=${x}
			break
		fi
		INDEX=$((INDEX+1))
	done
	echo "\nChosen file: ${x}\n"
else
# If $FILENAMES holds only one filename, it's value is assigned to $FILE.
	FILE=${FILENAMES}
fi

# $TYPE holds the type of the file held in $FILE
TYPE="$(file -b ${FILEPATH}${FILE} | awk '{print $1}')"

# If the type of $FILE differs from "gzip", the script exits with an exit code of "5".
if  [ "${TYPE}" != "gzip" ]
then
	echo "\n***ERROR***\nThere is no '.tar.gz.' file associated with Eclipse IDE inside ${FILEPATH} directory.\nScript will now exit.\n"
	exit 5
fi

# If execution reaches this point of the script, it means that there is a valid eclipse '.tar.gz'
# file inside $FILEPATH. The following part of the script is the one that conducts the installation.

# Extraction of the 'tar.gz' file in the current directory
sudo tar -zxvf ${FILEPATH}${FILE}
X1="$?"

# The 'eclipse' directory created from the extraction above is moved to /opt/
sudo mv ./eclipse/ /opt/
X2="$?"

# The 'eclipse.desktop' file is created
sudo echo  "[Desktop Entry]\nName=Eclipse\nType=Application\nExec=/opt/eclipse/eclipse\nTerminal=false\nIcon=/usr/share/pixmaps/eclipse.xpm\nComment=Intergrated Development Environment\nNoDisplay=false\nCategories=Development;" > eclipse.desktop
X3="$?"

# The '.desktop' file is installed and then deleted
sudo desktop-file-install eclipse.desktop
X4="$?"

sudo rm -rf eclipse.desktop
X5="$?"

# A soft link of eclipse's executable file is created in /usr/local/bin/eclipse
sudo ln -s /opt/eclipse/eclipse /usr/local/bin/eclipse
X6="$?"

# Eclipse's 'icon.xpm' is copied to /usr/share/pixmaps/ and renamed to 'eclipse.xpm'
sudo cp /opt/eclipse/icon.xpm /usr/share/pixmaps/eclipse.xpm
X7="$?"

# The exit code of each command is assigned to the variable $X1 to $X7.
# If there are no errors, each exit code equals to "0". The sum of all exit codes is assigned to $SUM.
SUM=$((X1+X2+X3+X4+X5+X6+X7))

# Finally, feedback about the installation status is given to the user according to the value of $SUM.
# If installation was NOT successful, the script exits with an exit code of "6".
# Note that in UNIX-like systems, the exit code is represented as an 8-bit unsigned(!) char [1-255].
if [ "${SUM}" -eq "0" ]
then
	echo "\n##################################################################################\n#\t\t\tThe installation was successful!\t\t\t #\n##################################################################################\n"
	exit 0
else
	echo "\n##################################################################################\n#\t\t\tThe installation was NOT successful!\t\t\t #\n##################################################################################\n"
	exit 6
fi
