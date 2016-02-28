/*
  Utility functions for Vernier sensor interface

  Written by BoB LeSuer 2/15/2016
  Do what you'd like with this code

*/
#ifndef UTILITY_H
#define UTILITY_H

// Needed for type definitions
#include "GoIO_DLL_interface.h"

float average(gtype_real64 v[], int n);
float standardDeviation(gtype_real64 v[], int n);

#endif
