/* 

  goio.h

  GoIO driver - part of the VernierPiLink project
  Copyright (c) 2016 BoB LeSuer
  Distributed under the MIT license

  Components of the GoIO software development kit are 
  Copyright (c) 2010 Vernier Software & Technology
  All rights reserved
  See LICENSE_VST.txt for complete license 

*/

#ifndef VERNIER_H
#define VERNIER_H

// Version numbers
#define GOIO_MAJOR_VERSION 1
#define GOIO_MINOR_VERSION 0
#define GOIO_PATCH_NUMBER 1
#define GOIO_RC_NUMBER 0

#define TARGET_OS_LINUX
#define GOIO_MAX_SIZE_DEVICE_NAME 260
#define MAX_NUM_MEASUREMENTS 1000 

// Error codes
#define ERR_OK 0
#define ERR_NO_DEVICE_FOUND 1

// for typedefs
#include "GoIO_DLL_interface.h"

void deviceopen();
void deviceconfigure(gtype_real64 measurementPeriod);
void deviceread();
void devicereadbuffer();
void deviceinfo();
void deviceunits();
void devicemeasurementperiod();
void deviceversion();
void deviceclose();
#endif

