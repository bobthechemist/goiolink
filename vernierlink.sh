#!/bin/bash

function pause(){
  read -n 1 -s -p "$*" RVAL
  echo
}

function checkstatus(){
  if test "$*" -eq 0
  then
    echo "Success"
  else
    echo "Problems found, please check the output above"
  fi
}

#if [[ $EUID -ne 0 ]]; then
#	echo "This script must be run with sudo"
#	exit 1
#fi

echo "STEP 1: Update and install packages"

# Check to see if wolfram is intalled
WOLFPRESENT=$(dpkg-query -W -f='${Status}' wolfram-engine 2>/dev/null | grep -c "ok installed")


if test $WOLFPRESENT -eq 0
then
  echo "Please install Mathematica with 'sudo apt install wolfram-engine'."
  exit 2
else
  echo "Mathematica is installed"
  LIB=$(find /opt -name libML32i4.so | head -n 1)
  echo "Setting up MathLink library"
  sudo cp $LIB /usr/local/lib
  sudo ldconfig
fi

# Install required packages
echo "Several packages will be installed in the next step"
pause "Pres 's' to skip this installation step, [Enter] to continue. "

if test "$RVAL" = "s"
then
  echo "Skipping installation of important packages, you have been warned."
else
  sudo apt install -y build-essential automake1.9 dpkg-dev libtool libusb-1.0-0-dev git uuid-dev
fi


echo "STEP 2: fetch and install Vernier SDK"

if test -f "GoIO-2.53.0.tar.gz"
then
  echo "It looks like you have downloaded the SDK aready."
else
  echo "Downloading the SDK ..."
  wget http://www2.vernier.com/download/GoIO-2.53.0.tar.gz
  checkstatus $?
fi

echo "unpacking the tarball"
if test -d "GoIO-2.53.0"
then
  echo "It looks like there is already an extracted directory."
  pause "I need to remove this directory.  Press 's' to skip this step, [Enter] to continue. "
  if test "$RVAL" =  "s"
  then
    echo "OK, not going to extract the tarball."
  else
    rm -r "GoIO-2.53.0"
    tar zxvf GoIO-2.53.0.tar.gz
    checkstatus $?
  fi
else
  # ugly redundancy
  tar zxvf GoIO-2.53.0.tar.gz
fi

echo "Updating the SDK files"

# Need to update a file
FILE=GoIO-2.53.0/GoIO_cpp/NonSmartSensorDDSRecs.cpp
cp $FILE $FILE.bak
sed -i '/\-1.*Averaging/s/\-1/(unsigned char)(\-1)/g' $FILE
sed -i '/\-1.*CurrentRequirement/s/\-1/(unsigned char)(\-1)/g' $FILE

checkstatus $?

echo "Building the SDK, this takes a few minutes."

cd GoIO-2.53.0
./build.sh
echo "Checking if the SDK built ok ..."
checkstatus $?
cd GoIO_DeviceCheck
./build.sh
echo "Checking if the test program built ok ..."
checkstatus $?
cd ../..

echo "STEP 3: Check that SDK is working"

read -p "Attach the Go!Link and a sensor, then press [Enter] to continue ..."
./GoIO-2.53.0/GoIO_DeviceCheck/GoIO_DeviceCheck
echo "You should see a reading here - I'm not smart enough to tell if it worked."
pause "If something went wrong, press 's' to stop the install, or [Enter] to continue. "

if test "$RVAL" = "s"
then
  echo "Exiting ..."
  exit 2
fi

echo "STEP 4: Install goiolink"

# Check of goiolink is already installed.
if test -d "goiolink"
then
  echo "A previous installation of goiolink is found."
  pause "I need to remove it.  Press 's' to skip this step, or [Enter] to continue."
fi

if test "$RVAL" = 's'
then
  echo "skipping goiolink install"
else
  if test -d "goiolink"
  then
    echo "removing goiolink directory"
    sudo rm -r "goiolink"
    checkstatus $?
  fi
  git clone https://github.com/bobthechemist/goiolink.git
  cd goiolink
  make
  checkstatus $?
  cd ..
fi

# Installing driver, deleting old files if necessary

pause "Installing goiolink driver and will delete old driver if present.  Press 's' to skip this step or [Enter] to continue."
if test "$RVAL" = "s"
then
  echo "Skipping driver install."
else
  rm -r "./.Mathematica/Applications/GoIO" 2>/dev/null
  mkdir "./.Mathematica/Applications/GoIO"
  cp goiolink/GoIO.m ./.Mathematica/Applications/GoIO
  cp goiolink/goio ./.Mathematica/Applications/GoIO
fi

echo "Installation finished.  Let's check if it works."

wolframscript -c "<<GoIO\`;d=DeviceOpen[\"GoIO\"];d[\"Read\"]"

if test "$?" -eq 0
then
  echo "You should see a sensor value above, if so, all is well."
else
  echo "There might be a problem."
  echo $?
fi


