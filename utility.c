/* 
  utility functions for Vernier sensor applications
  Written by BoB LeSuer, 2016
  Do what you'd like with this code
*/

#include "utility.h"
#include "math.h"
#include <sys/time.h>
#include <time.h>

float average(gtype_real64 v[], int n)
{
  int i;
  float sum = 0.0;
  for (i = 0; i<n;i++)
  {
    sum += v[i];
  }

  return sum/n;
}

float standardDeviation(gtype_real64 v[], int n)
{
  int i;
  float sum = 0.0;
  float avg = average(v,n);
  for (i = 0; i<n;i++)
  {
    sum += pow(v[i]-avg,2);
  }

  return sqrt(sum/(n-1));
}


