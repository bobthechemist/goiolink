/*
  code cut and pasted from either the Vernier SDK or sample programs therein
*/

#ifndef VUTILITY_H
#define VUTILITY_H

// for namespace typedefs
#include "GoIO_DLL_interface.h"
#include <stdbool.h>

extern char *deviceDesc[8] ; 
bool GetAvailableDeviceName(char *deviceName, gtype_int32 nameLength, gtype_int32 *pVendorId, gtype_int32 *pProductId);
void vSleep(unsigned long msToSleep);

#endif
