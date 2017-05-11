# GoIO Link
A device driver and *Mathematica* package to access Vernier Software & Technology sensors on your Raspberry Pi using
a Go! Link USB adapter and the Wolfram Language.  The flagship component of my VernierPiLink project.

# Installation

## The easy way
You may head on over to the releases and download the zip file containing the driver (goio) and *Mathematica* package (GoIO.m).  These two files must be copied into a directory named '/home/pi/.WolframEngine/Applications/GoIO'.  You can replace "pi" with your username if you have done so.

## The other way (only slightly less easy)
### Install and compile the Vernier SDK
The following set of commands will allow you to download and install the Vernier Software & Technology Software Development Kit for Go! Link devices.
```
cd ~
wget http://www2.vernier.com/download/GoIO-2.53.0.tar.gz
tar zxvf GoIO-2.53.0.tar.gz
sudo aptitude install build-essential automake1.9 dpkg-dev libtool libusb-1.0-0-dev
sudo apt-get install git uuid-dev
cd GoIO-2.53.0
./build.sh
```
Check to see that the SDK was installed properly by running the example file that came with the SDK:
```
cd ~/GoIO-2.53.0/GoIO_DeviceCheck
./build.sh 
./GoIO_DeviceCheck
```
### Clone this repository
use `git clone https://github.com/bobthechemist/goiolink.git` and after entering the newly created directory type `make goio`.  The makefile does not do any installing, so you will have to manually move the goio and GoIO.m files as mentioned above.

## How to use
In a Mathematica session (initiated either from the command line with `wolfram` or the notebook interface via `mathematica`) you need to first load the package with `<<GoIO`` and then open the device with `d = DeviceOpen["GoIO"]`.  Now, assuming you have the Go! Link USB adapter connected to the RPi and a sensor connected to the adapter, you can type `d["Read"]` for a sensor measurement.  In the notebook interface, you can try `goioRTInterface[d]` which will create a real-time plot of the sensor readings.  Additional documentation to come.

### Current functionality
- d["Read"] reads the current sensor value, which is the average of all values currently in the Go! Link buffer
- d["ReadLong"] returns the standard deviation and number of readings that were in the buffer as well
- d["ReadAll"] returns all the values in the buffer
- d["Units"] returns the units of the sensor response
- d["Name"] is the name of the sensor
- d["MeasurementPeriod"] returns the current sensor measurement period (default is 0.04 s).  This property can be used to set the sensor measurement period as well.  It is recommended that this value not be set below 0.02 s.  
- d["Calibration"] returns the three coefficients of the calibration equation, and a 4th number corresponding to the function type (e.g. linear, exponential, ...)
- goioVersion[] returns version information for the Vernier SDK, device driver and Mathematica package

## General issues at present
- Sensors can be interchanged without restarting Mathematica; however the change is not detected automatically.  Whenever changing the sensor, type `DeviceConfigure[d]` to refresh the sensor information.
- The current version of the code does not do a lot of error checking.  The biggest problem appears to be when the device is closed, since there appears to be some persistent symbols that make a mess of things.  Best to restart Mathematica if you see things go awry.
- Dynamic notebook functions are still very clunky on the RPi.  As such, features like `goioRTInterface[]` should be considered toys.  It should be possible to create interactive interfaces that aren't as memory intensive, and that project is in the works.
