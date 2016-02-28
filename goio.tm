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
:Begin:
:Function:	    deviceopen 
:Pattern:	      GoIO`vplDeviceOpen[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    deviceconfigure 
:Pattern:	      GoIO`vplDeviceConfigure[measurementPeriod_Real]
:Arguments:	    {measurementPeriod}
:ArgumentTypes:	{Real}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    deviceread
:Pattern:	      GoIO`vplDeviceRead[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    devicereadbuffer
:Pattern:	      GoIO`vplDeviceReadBuffer[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    deviceunits 
:Pattern:	      GoIO`vplDeviceUnits[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    devicecalibration 
:Pattern:	      GoIO`vplDeviceCalibration[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    deviceinfo 
:Pattern:	      GoIO`vplDeviceInfo[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    devicemeasurementperiod 
:Pattern:	      GoIO`vplDeviceMeasurementPeriod[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    deviceversion 
:Pattern:	      GoIO`vplDeviceVersion[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
:Begin:
:Function:	    deviceclose 
:Pattern:	      GoIO`vplDeviceClose[]
:Arguments:	    {}
:ArgumentTypes:	{}
:ReturnType:	  Manual
:End:
