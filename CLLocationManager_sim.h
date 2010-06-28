//-----------------------------------------------------------------------------
//  CLLocationManager_sim.h
//
//  This class can be used as a replacement for CLLocationManager.
//
//  When compiled for the iPhone/iPad simulator it provides the ability to
//  get a different location and optionally have it moving for testing apps.
//
//  When compiled for an iOS device, all the simulator code is left out and
//  you get only the original unchanged functionality of the CLLocationManager.
//
//-----------------------------------------------------------------------------
//  Created by Gary Morris on 6/26/10.
//  Copyright 2010 Gary A. Morris. All rights reserved.
//-----------------------------------------------------------------------------

#import <CoreLocation/CoreLocation.h>

#if TARGET_IPHONE_SIMULATOR
typedef enum { simLatitude, simLongitude, simAltitude, simTimestamp, simHorizontalAccuracy, simVerticalAccuracy, N_STATE_DATA } SimStateType;

@interface CLLocationManager_sim : CLLocationManager <CLLocationManagerDelegate>
{
	// replacements for super's ivars:
	id<CLLocationManagerDelegate> simDelegate;	// delegate
	CLLocation* simLocation;			// last reported location
	
	//---------------------------------
	// ivars to support simulation:
	//---------------------------------
	double simState[N_STATE_DATA];		// simulation state data
	unsigned nextUpdate;				// index into state updates
	CFAbsoluteTime simStartTime;		// time that sim was enabled
	NSTimer* simTimer;					// performs sim updates periodically
}

// override CLLocationManager's properties
@property (assign, nonatomic) id<CLLocationManagerDelegate> delegate;
@property (readonly, nonatomic) CLLocation* location;

#else
@interface CLLocationManager_sim : CLLocationManager { }
#endif

@end
