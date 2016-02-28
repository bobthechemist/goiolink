(* Written by BoB LeSuer (2016)        *)
(* - Device driver for the Vernier Go! Link sensors *) 
BeginPackage["GoIO`"]

(* During design, assume that the MathLink program is in the working directory *)
$GoIOLink = Install[FileNameJoin[{$UserBaseDirectory,"Applications","GoIO","goio"}]];
$GoIOLinkVersion = "1.0.0";
voltageConvert::usage = "Converts a sensor voltage reading based on a given equation"
goioVersion::usage = "Returns version information"
goioRTInterface::usage = "goioRTInterface[device] is a simple real time interface displaying a plot and buttons to start/stop the sensor"

goio::readonly = " `1` is read only."

DeviceFramework`DeviceClassRegister["GoIO",
  "ReadFunction"->(GoIO`voltageConvert[First@GoIO`vplDeviceRead[],GoIO`vplDeviceCalibration[]]&),
  "ReadBufferFunction"->(GoIO`vplDeviceReadBuffer[]&),
  "OpenFunction"->GoIO`Private`openRoutine,
  "WriteFunction"->(GoIO`vplDeviceWrite[]&),
  "ExecuteFunction"->GoIO`Private`executeCommand,
  "ConfigureFunction"->GoIO`Private`configure,
  "CloseFunction"->(GoIO`vplDeviceClose[]&),
  "DeregisterOnClose"->False, 
  "Singleton"->True, (* Only one GoIO connection allowed at this time *)
  "NativeProperties"->{ (* I define NativeProperties as those that require the MathLink code to *SET* their value *)
    "MeasurementPeriod"
  },
  "GetNativePropertyFunction"->GoIO`Private`getNativeProp,
  "SetNativePropertyFunction"->GoIO`Private`setNativeProp,
  "Properties"->{ (* Null indicates property is a method and cannot be assigned a value *)
    "Read"->Null,
    "ReadLong"->Null,
    "ReadAll"->Null,
    "Units"->Null,
    "Name"->Null,
    "Calibration"->Null,
    (* When parameters are initially set, they are passed to [function tbd] in alphabetical order *)
    (* Naming initialization variable is meant to make it be evaluated last, which is my way of   *)
    (* indicating that the initialization sequence is complete.  This is done to avoid seeing a   *)
    (* bunch of read-only error messages during startup.  Note that end user can change this      *)
    (* value with unintended effects. Does not mask warnings after a DeviceClose.                 *)
    "ZZInitialized"->True,
    "ReturnType"->"Value" (* Not used *)
  },
  "SetPropertyFunction"->GoIO`Private`setProp,
  "GetPropertyFunction"->GoIO`Private`getProp
  

];

Begin["`Private`"]
  
  (* Eventually append CreateUUID[] when device driver is nearly finished *)
  openRoutine[_,args___]:=Module[{},
    GoIO`vplDeviceOpen[];
  ]
  
  (* Call when user changes the sensor connected to GoIO! Link *)
  (* 
    No longer needed, use DeviceConfigure[devHandle]
  executeCommand[_,"Refresh"] := (DeviceClose["GoIO"];DeviceOpen["GoIO"]);
  *)

  (* Property setting - Hacked to allow some properties to call functions *)
  (*   and therefore behave as methods, which do not appear to be implemented *)
  (* $methods contains all properties that cannot be set *)
  $methods = {"Read", "Units", "Calibration","Name", "ReadAll","ReadLong"};
  setProp[devHandle_,prop_, rhs_]:=If[MemberQ[$methods,prop],
    If[properties[devHandle]["ZZInitialized"]===True,Message[goio::readonly,prop]], 
    properties[devHandle][prop]=rhs];
  getProp[devHandle_,prop_]:=properties[devHandle][prop]
  properties[_]["Read"] := GoIO`voltageConvert[First@GoIO`vplDeviceRead[],GoIO`vplDeviceCalibration[]]
  properties[_]["Units"] := GoIO`vplDeviceUnits[]
  properties[_]["Calibration"]:=GoIO`vplDeviceCalibration[]
  properties[_]["Name"]:=GoIO`vplDeviceInfo[] 
  properties[_]["ReadAll"] := GoIO`voltageConvert[#,GoIO`vplDeviceCalibration[]]&/@GoIO`vplDeviceReadBuffer[]
  (* Assuming that standard deviation can be converted from volts to sensor units using *)
  (* sf = |f(v)-f(v+sv)| *)
  properties[_]["ReadLong"]:= Module[{rin,rout},
    rout = rin = GoIO`vplDeviceRead[];
    rout[[1]] = GoIO`voltageConvert[rin[[1]],GoIO`vplDeviceCalibration[]];
    rout[[2]] = Abs[rout[[1]]-GoIO`voltageConvert[rin[[1]]+rin[[2]],GoIO`vplDeviceCalibration[]]];
    rout
  ]
  getNativeProp[devHandle_,prop_]:=nproperties[devHandle][prop]
  setNativeProp[devHandle_,prop_,rhs_]:=nproperties[devHandle][prop,rhs]
  nproperties[_]["MeasurementPeriod"]:=GoIO`vplDeviceMeasurementPeriod[];
  nproperties[devHandle_]["MeasurementPeriod",rhs_]:=GoIO`vplDeviceConfigure[N@rhs];
  (* Configure sensor options.  Presently only the measurement period can be changed. *)
  (* All options sent in association *)
  configure[{_,h_},assoc_]:= Module[{},
    mp = Lookup[assoc,"measurementPeriod",0.040];
    GoIO`vplDeviceConfigure[mp];
  ];
  (* DeviceConfigure[devHandle] can be used to refresh the sensor such as during a sensor change *)
  configure[{d_,h_}] := configure[{d,h},Association[]];

  (* Voltage conversion functions - see GoIO_cpp/GSensorDDSMem.h for equation type *)
  voltageConvert[x_,{a_,b_,c_,1.}]:=b x + a;
  voltageConvert[x_,{a_,b_,c_,2.}]:=c x^2 + b x + a;
  voltageConvert[x_,{a_,b_,c_,3.}]:=a x^b;
  voltageConvert[x_,{a_,b_,c_,4.}]:=a b^x;
  voltageConvert[x_,{a_,b_,c_,5.}]:=a + b Log[x];
  voltageConvert[x_,{a_,b_,c_,6.}]:=a + b Log[1/x];
  voltageConvert[x_,{a_,b_,c_,7.}]:=a Exp[b x];
  voltageConvert[x_,{a_,b_,c_,8.}]:=a Exp[b/x];
  voltageConvert[x_,{a_,b_,c_,9.}]:=a x^(b x);
  voltageConvert[x_,{a_,b_,c_,10.}]:=a x^(b/x);
  voltageConvert[x_,{a_,b_,c_,11.}]:=1/(a+b+Log[c x]); 
  (* SteinhartHart - for thermisters - requires resistance *)
  voltageConvert[x_,{a_,b_,c_,12.}]:=Module[{r = 15000, maxv = 5,v, x2},
    v = If[x>0.999 maxv,0.999 maxv,If[x<0.001 maxv,0.001 maxv,x]];
    x2 = (x*r)/(maxv-v);
    1/(a+b*Log[x2]+c*(Log[x2]^3)) - 273.15
    ];


  goioVersion[]:=Module[{v, vs ,output},
    v = GoIO`vplDeviceVersion[];
    vs = ToString/@v;
    output = StringJoin[{
      {"\n"},
      {"GoIO DLL version: ",vs[[1]],".",vs[[2]],"\n"},
      {"GoIO driver version: ",vs[[3]],".",vs[[4]],".",vs[[5]],
        If[v[[6]]>0,"RC"<>vs[[6]],""],"\n"},
      {"GoIO Mathematica Link version: ", $GoIOLinkVersion,"\n"}
    }];
    Print[output];
  ]

  addData[old_List, new_DeviceObject]:=With[{l = Length@old},
    Append[If[l<100,old,old[[l-99;;]]],{Now,new["Read"]}]]

  goioRTInterface[dev_DeviceObject]:=Module[{data = {},tsk,title="Not running", starttime, isrunning = False, emsg = ""},
    Pane[
      Row[{
        Dynamic@DateListPlot[data,ImageSize->Medium, Axes->False,Frame->{True,True,False,False},
          FrameLabel->{"Time",dev["Units"]}],
        Column[{
          Dynamic@title,
          Button["Start sensor", (
            tsk = CreateScheduledTask[data = addData[data,dev],1];
            starttime = Now;
            StartScheduledTask[tsk];
            title = "Sensor: "<>dev["Name"];
            isrunning = True;
          )],
          Button["Stop sensor", (
            RemoveScheduledTask[tsk];
            title = "Not Running";
            isrunning = False;
          )],
          Button["Refresh sensor", (
            If[isrunning,
              emsg = "Shut off sensor first",
              (
                emsg = "";
                data = {};
                DeviceConfigure[dev];
              )
            ]
          )],
          Dynamic@emsg

        }]
      }],
      {560,230}
    ]
  ]

End[]


EndPackage[]

