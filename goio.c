/* 

  goio.c

  GoIO driver - part of the VernierPiLink project
  Copyright (c) 2016 BoB LeSuer
  Distributed under the MIT license

  Components of the GoIO software development kit are 
  Copyright (c) 2010 Vernier Software & Technology
  All rights reserved
  See LICENSE_VST.txt for complete license 

*/

#include <stddef.h> // includes NULL definition
#include <string.h>

#include "goio.h"
#include "vutility.h"
#include "utility.h"
#include "GoIO_DLL_interface.h"
#include "mathlink.h"

// I think the device handle needs to be global
GOIO_SENSOR_HANDLE hDevice;

int main(int argc, char* argv[])
{
  return MLMain(argc, argv);

}

/* 
  Creates a device handle and starts the sensor with a default measurement period
  Returns 0 if all OK and 1 if there is an error. However, the return value is not
  observed in Mathematica when DeviceOpen is called, so it is of little use.
*/
void deviceopen()
{
  char deviceName[GOIO_MAX_SIZE_DEVICE_NAME];
  gtype_int32 vendorId, productId;

  // May want to add additional code here to check if deviceopen is called when device is already open
  hDevice = NULL;

  GoIO_Init();
  bool bFoundDevice = GetAvailableDeviceName(deviceName, GOIO_MAX_SIZE_DEVICE_NAME, &vendorId, &productId);
  if (!bFoundDevice)
  {
    MLPutDouble(stdlink, ERR_NO_DEVICE_FOUND);
    return;
  }
  else
  {
    while (hDevice == NULL)
    {
      hDevice = GoIO_Sensor_Open(deviceName, vendorId, productId, 0);
    }
    GoIO_Sensor_SetMeasurementPeriod(hDevice, 0.040, SKIP_TIMEOUT_MS_DEFAULT);
    GoIO_Sensor_SendCmdAndGetResponse(hDevice, SKIP_CMD_ID_START_MEASUREMENTS, NULL, 0, NULL, NULL, SKIP_TIMEOUT_MS_DEFAULT);
    MLPutDouble(stdlink, ERR_OK);
  }
  return;
}

/*
  deviceconfigure allows for sensor variables to be adjusted.  Presently, the only parameter worth adjusting is the
  measurement period.  Not tested for measurement periods below 0.04 and presumably values at or below 0.02 will
  result in some problems.
*/
void deviceconfigure(gtype_real64 measurementPeriod)
{
  /* 
    At this point, configure is simply a rehash of deviceopen with the ability to change some paramters.  It 
    will close and re-establish the device handle, which means it should also be useful as a device refresh
    in the event that the user switches sensors.
  */

  char deviceName[GOIO_MAX_SIZE_DEVICE_NAME];
  gtype_int32 vendorId, productId;

  if (hDevice != NULL)
  {
    GoIO_Uninit();
  }

  hDevice = NULL;

  GoIO_Init();
  bool bFoundDevice = GetAvailableDeviceName(deviceName, GOIO_MAX_SIZE_DEVICE_NAME, &vendorId, &productId);
  if (!bFoundDevice)
  {
    MLPutDouble(stdlink, ERR_NO_DEVICE_FOUND);
    return;
  }
  else
  {
    while (hDevice == NULL)
    {
      hDevice = GoIO_Sensor_Open(deviceName, vendorId, productId, 0);
    }
    GoIO_Sensor_SetMeasurementPeriod(hDevice, measurementPeriod, SKIP_TIMEOUT_MS_DEFAULT);
    GoIO_Sensor_SendCmdAndGetResponse(hDevice, SKIP_CMD_ID_START_MEASUREMENTS, NULL, 0, NULL, NULL, SKIP_TIMEOUT_MS_DEFAULT);
    MLPutDouble(stdlink, ERR_OK);
  }
  return;

}
/*
  Returns an array of length 3 contianing the average voltage of all measurements currently in the 
  buffer, the standard deviation of that number, and the number of measurements that were in the buffer.
  Due to problems I have noticed with the Vernier SDK, I am off-loading the calibration procedure to 
  Mathematica.  The greatest impact of this decision is that the standard deviation cannot be easily 
  converted to the sensor units.
*/
void deviceread()
{
  int i;
  gtype_int32 numMeasurements;
  gtype_int32 rawMeasurements[MAX_NUM_MEASUREMENTS];
  gtype_real64 volts[MAX_NUM_MEASUREMENTS];
  gtype_real64 output[3];

  numMeasurements = GoIO_Sensor_ReadRawMeasurements(hDevice, rawMeasurements, MAX_NUM_MEASUREMENTS);
  for (i = 0; i < numMeasurements; i++)
  {
    volts[i] = GoIO_Sensor_ConvertToVoltage(hDevice, rawMeasurements[i]);
  }
  output[0] = average(volts,numMeasurements);
  output[1] = standardDeviation(volts,numMeasurements);
  output[2] = (gtype_real64)numMeasurements;
  MLPutRealList(stdlink, output,3);
  return;
  
}

/*
  devicereadbuffer() is similar to deviceread except that it does not aggregate the results and 
  instead returns all values currently in the buffer.  One may be interested in using this routine
  for high-speed data acquisition, but care must be made to ensure that the buffer was cleared
  prior to starting the measurements (two read operations would do the trick) and that fewer than
  1000 measurements are collected (at which point it is probable that the initial data were over-
  written due to the circular nature of the GoIO! Link buffer.
*/
void devicereadbuffer()
{
  int i;
  gtype_int32 numMeasurements;
  gtype_int32 rawMeasurements[MAX_NUM_MEASUREMENTS];
  gtype_real64 volts[MAX_NUM_MEASUREMENTS];

  numMeasurements = GoIO_Sensor_ReadRawMeasurements(hDevice, rawMeasurements, MAX_NUM_MEASUREMENTS);
  for (i = 0; i < numMeasurements; i++)
  {
    volts[i] = GoIO_Sensor_ConvertToVoltage(hDevice, rawMeasurements[i]);
  }
  MLPutRealList(stdlink, volts,numMeasurements);
  return;
  
}

/*
  deviceinfo returns the name of the sensor currently attached to the Go! Link.  A 
  sensor name of "Missing" is reported if the sensor is not connected.
*/
void deviceinfo()
{
  char sensorName[100];

  GoIO_Sensor_DDSMem_GetLongName(hDevice, sensorName, sizeof(sensorName));
  if (strlen(sensorName) != 0)
  {
    MLPutString(stdlink, sensorName);
  }
  else
  {
    MLPutString(stdlink, "Missing");
  }
  return;
}

/*
  deviceunits grabs the units of the sensor response after the calibration function is applied.
*/
void deviceunits()
{
  unsigned char calPage = 0;
  gtype_real32 a, b, c;
  char units[20];
  char equationType = 0;
  GoIO_Sensor_DDSMem_GetActiveCalPage(hDevice, &calPage);
  GoIO_Sensor_DDSMem_GetCalPage(hDevice, calPage, &a, &b, &c, units, sizeof(units));
  if (strlen(units) != 0)
  {
    MLPutString(stdlink, units);
  }
  else
  {
    MLPutString(stdlink, "Missing");
  }

}

/*
  devicecalibration returns a list containing the calibration function information.  The return value
  is a list of three reals plus a 4th real containing a function identifier.  The Vernier SDK provides
  a routine to convert sensor voltage to calibrated units; however in my testing, I found that this
  function was failing (for reasons unclear to me) which resulted in data being lost.  To work around
  this problem, I have off-loaded voltage-to-real unit routines to Mathematica, and it does not appear
  as if there is any significant performance hit at this time.
*/
void devicecalibration()
{
  unsigned char calPage = 0;
  gtype_real32 a,b,c;
  gtype_real32 calList[4];
  char units[20];
  char equationType = 0;
  GoIO_Sensor_DDSMem_GetActiveCalPage(hDevice,&calPage);
  GoIO_Sensor_DDSMem_GetCalPage(hDevice, calPage, &a, &b, &c, units, sizeof(units));
  GoIO_Sensor_DDSMem_GetCalibrationEquation(hDevice, &equationType);
  calList[0] = a;
  calList[1] = b;
  calList[2] = c;
  calList[3] = (gtype_real32)equationType;
  MLPutReal32List(stdlink,calList, 4);

}

/* 
  devicemeasurementperiod returns the current measurement period for the sensor
*/
void devicemeasurementperiod()
{
  gtype_real64 measurementPeriod;
  measurementPeriod = GoIO_Sensor_GetMeasurementPeriod(hDevice, SKIP_TIMEOUT_MS_DEFAULT);
  MLPutDouble(stdlink, measurementPeriod);
  return;
}

/*
  deviceversion returns version information in the form of a list.  The order of the numbers is:
  GoIO SDK Major version, minor version, GoIO driver major version, minor, patch and release candidate.
  If release candidate is 0, then that means it is unused and should be ignored (following semver.org here).

*/
void deviceversion()
{
  gtype_uint16 pMajorVersion, pMinorVersion;
  int returnval[6];

  GoIO_GetDLLVersion(&pMajorVersion, &pMinorVersion);
  returnval[0] = (int)pMajorVersion;
  returnval[1] = (int)pMinorVersion;
  returnval[2] = (int)GOIO_MAJOR_VERSION;
  returnval[3] = (int)GOIO_MINOR_VERSION;
  returnval[4] = (int)GOIO_PATCH_NUMBER;
  returnval[5] = (int)GOIO_RC_NUMBER;

  MLPutIntegerList(stdlink,returnval,6);
}

/*
  deviceclose closes the sensor and releases the handle.  It generates a return value with
  information in the event of an error; however Mathematica's DeviceClose[] function does not
  capture the return value so it is of little use at the moment.
*/
void deviceclose()
{
  int closeresult = 0;
  int uninitresult = 0;

  closeresult = GoIO_Sensor_Close(hDevice);
  uninitresult = GoIO_Uninit();
  hDevice = NULL;

  MLPutDouble(stdlink, closeresult + 2 * uninitresult);
}

