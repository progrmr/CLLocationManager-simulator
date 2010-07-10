//-----------------------------------------------------------------------------
//  CLLocationManager_sim.h
//
//  Created by Gary Morris on 6/26/10.
//
//-----------------------------------------------------------------------------
//
//  Copyright 2010 Gary A. Morris.  http://mggm.net
//
//  This file is part of CLLocationManager_sim.
//
//  CLLocationManager_sim is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CLLocationManager_sim is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//  
//  You should have received a copy of the GNU Lesser General Public License
//  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
//-----------------------------------------------------------------------------

#import "CLLocationManager_sim.h"


@implementation CLLocationManager_sim

#if TARGET_IPHONE_SIMULATOR
@dynamic delegate, location;

typedef struct {
	SimStateType   state;	// which state data
	double		   data;	// state data value
	CFTimeInterval time;	// time, relative to start of sim
} SimStateUpdateType;

enum { ACCURACY_INVALID = -1 };			// indicates invalid data
const double SIM_UPDATE_PERIOD = 1.0;	// use to set the timer interval

// SIM_SCENARIO selects a set of simulator command to control how is behaves
// This is a compile time flag.  It would be nice to read commands from a file
// but that's not implemented yet.
#define SIM_SCENARIO 2

static const SimStateUpdateType simStateUpdates[] = {
#if SIM_SCENARIO==0
	// Scenario: original iPhone simulator just returns lat/lon of Apple HQ in Cupertino
	// Take from: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/125-Using_iPhone_Simulator/iphone_simulator_application.html#//apple_ref/doc/uid/TP40007959-CH9-SW10
	{ simHorizontalAccuracy,  100, 0.0 },
	{ simLatitude,        37.3317, 0.0 },	
	{ simLongitude,     -122.0307, 0.0 },
	
#elif SIM_SCENARIO==1
	// Scenario: initial state will indicate no valid data and
	//           valid data will appear a few seconds later and
	//           accuracy will improve over the next minute
	// provide a location but with low accuracy
	{ simHorizontalAccuracy, 1200,  3.0 },	// Got a location via cell triangulation
	{ simLatitude,           33.1,  3.0 },	// latitude of Escondido
	{ simLongitude,        -117.1,  3.0 },	// longitude of Escondido
	
	// improve accuracy as we acquire GPS satellites
	{ simHorizontalAccuracy,  300, 30.0 },	// Got a poor location via GPS

	// add vertical position as we acquired 3D GPS position
	{ simHorizontalAccuracy,   30, 40.0 },	// Better
	{ simVerticalAccuracy,     30, 40.0 },	// Have altitude now
	{ simAltitude,            250, 40.0 },	// Escondido altitude
	
	// finally, best accuracy
	{ simHorizontalAccuracy,   10, 75.0 },
	
#elif SIM_SCENARIO==2
	// Scenario: initial state will provide old cached data and
	//           valid data will appear a few seconds later and
	//           accuracy will improve over the next minute
	{ simLatitude,           33.5,  0.0 },
	{ simLongitude,        -117.5,  0.0 },
	{ simHorizontalAccuracy,   10,  0.0 },	// best GPS accuracy
	{ simVerticalAccuracy,     30,  0.0 },  // best GPS accuracy
	{ simTimestamp,         -3600,  0.0 },  // simulate cached data, 3600 seconds old
	
	// now provide a location but with low accuracy
	{ simHorizontalAccuracy, 1000,  3.0 },	// cell triangulation accuracy
	{ simVerticalAccuracy,     -1,  3.0 },  // no altitude data now
	{ simAltitude,             -1,  3.0 },  // no altitude data now
	{ simLatitude,          33.15,  3.0 },	// latitude of Escondido
	{ simLongitude,       -117.15,  3.0 },	// longitude of Escondido
	{ simTimestamp,          -0.1,  3.0 },  // recent timestamp, 100ms ago
	
	// improve accuracy as we acquire GPS satellites
	{ simHorizontalAccuracy,  300, 20.0 },	// Got a poor location via GPS
	{ simLatitude,          33.11, 20.0 },	// latitude of Escondido
	{ simLongitude,       -117.11, 20.0 },	// longitude of Escondido
	
	// add vertical position as we acquired 3D GPS position
	{ simLatitude,           33.1, 30.0 },	// latitude of Escondido
	{ simLongitude,        -117.1, 30.0 },	// longitude of Escondido
	{ simHorizontalAccuracy,   30, 30.0 },	// Better
	{ simVerticalAccuracy,     30, 30.0 },	// Have altitude now
	{ simAltitude,            250, 30.0 },	// Escondido altitude
	
	// finally, best accuracy
	{ simHorizontalAccuracy,   10, 50.0 },
	
#else
#error Need to provide simulation data
#endif
};	


//---------------------------------------------------------------------
// dealloc
//---------------------------------------------------------------------
-(void)dealloc
{
	[simTimer invalidate];
	[simLocation release];
	
	[super dealloc];
}

//---------------------------------------------------------------------
// init
//---------------------------------------------------------------------
-(id)init
{
	if (self = [super init]) {
		// initialize simStateData with all zeroes
        for (int i=0; i < sizeof(simState)/sizeof(simState[0]); i++) {
			simState[i] = 0.0;
		}
		simState[simHorizontalAccuracy] = ACCURACY_INVALID;
		simState[simVerticalAccuracy]   = ACCURACY_INVALID;
		simState[simAltitude] = -1;
		
		nextUpdate = 0;
		simStartTime = -1.0;		// not started yet
	}
	return self;
}

//---------------------------------------------------------------------
// delegate property - overrides property in CLLocationManager
//---------------------------------------------------------------------
-(void)setDelegate:(id <CLLocationManagerDelegate>)newDelegate
{
	simDelegate = newDelegate;
	
	// insert self as delegate in between
	[super setDelegate: newDelegate ? self : nil];
}

-(id <CLLocationManagerDelegate>)delegate
{
	return simDelegate;
}

//---------------------------------------------------------------------
// location property - overrides property in CLLocationManager
//    (location property stored in simLocation ivar)
//---------------------------------------------------------------------
-(void)setLocation:(CLLocation*)newLocation
{
	[newLocation retain];
	[simLocation release];
	simLocation = newLocation;
}

-(CLLocation*)location
{
	return [[simLocation retain] autorelease];
}

//---------------------------------------------------------------------
// updateSimState - call periodically to update simulator state,
//    processes the next state updates if it is time for them.
//    returns BOOL which indicates if location changed
//---------------------------------------------------------------------
-(BOOL)updateSimState
{	
	const unsigned nUpdates = sizeof(simStateUpdates) / sizeof(simStateUpdates[0]);
	const CFTimeInterval simTime = CFAbsoluteTimeGetCurrent() - simStartTime;
	BOOL locationChanged = NO;
	BOOL done = nextUpdate >= nUpdates;
	
	while (!done && simStateUpdates[nextUpdate].time <= simTime) {
		// perform the sim state data update, it's time has come
		simState[simStateUpdates[nextUpdate].state] = simStateUpdates[nextUpdate].data;
		locationChanged = YES;		// an update was made
		done = ++nextUpdate >= nUpdates;
	}

	if (done) {
		// no more simulator commands
		[simTimer invalidate];
		simTimer = nil;
	}
	
	return locationChanged;
}

//---------------------------------------------------------------------
// simulatorTask - called once per second perform next callback
//---------------------------------------------------------------------
-(void)simulatorTask
{
	const BOOL locChanged = [self updateSimState];
	
	if (!locChanged) return;
	
	// location changed, create a new CLLocation value, call delegate
	CLLocationCoordinate2D coordinates = { simState[simLatitude], simState[simLongitude] };
	NSDate* timestamp = [NSDate dateWithTimeIntervalSinceNow:simState[simTimestamp]];
	
	CLLocation* oldLoc = self.location;
	CLLocation* newLoc = 
		[[CLLocation alloc] initWithCoordinate:coordinates 
									  altitude:simState[simAltitude]
							horizontalAccuracy:simState[simHorizontalAccuracy]
							  verticalAccuracy:simState[simVerticalAccuracy]
									 timestamp:timestamp];
	
	// call the delegate with the new location
	if (simDelegate && [simDelegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
	{
		//---------------------------
		// Apply distanceFilter
		//---------------------------
		// (if no filter we always have moved enough)
		BOOL isValid = newLoc.horizontalAccuracy >= 0;
		BOOL meetsDistanceFilter = self.distanceFilter == kCLDistanceFilterNone;
		
		if (!meetsDistanceFilter) {
			if (oldLoc==nil || oldLoc.horizontalAccuracy < 0) {
				// old location is not valid, filter is met if valid now
				meetsDistanceFilter = isValid;
				
			} else if (isValid) {
				// compute distance from last location
				CLLocationDistance distance = [newLoc distanceFromLocation:oldLoc];
				meetsDistanceFilter = distance >= self.distanceFilter;
			}
		}
		
		//-------------------------------------
		// Deliver the location change event
		//-------------------------------------
		if (meetsDistanceFilter) {
			[simDelegate locationManager:self didUpdateToLocation:newLoc fromLocation:oldLoc];
			self.location = newLoc;		// update current location
		
		} else if (!isValid) {
			// new location is invalid, send an error to the delegate
			NSError* error = [NSError errorWithDomain:@"CLLocationManager"
												 code:kCLErrorLocationUnknown
											 userInfo:nil];
			[simDelegate locationManager:self didFailWithError:error];
			self.location = newLoc;		// update current location
		}
	}
	
	[newLoc release];
}

//---------------------------------------------------------------------
// start/stopUpdatingLocation
//---------------------------------------------------------------------
-(void)startUpdatingLocation
{
	if (simStartTime < 0) {
		simStartTime = CFAbsoluteTimeGetCurrent();
	}
	
	if (simTimer == nil) {
		simTimer = [NSTimer scheduledTimerWithTimeInterval:SIM_UPDATE_PERIOD 
													target:self 
												  selector:@selector(simulatorTask) 
												  userInfo:nil 	
												   repeats:YES];	
		[self simulatorTask];	// initial call, subsequently called by timer
	}
	
	// start real CLLocationManager in case we are running on a 
	// real device we can allow it to provide region or heading
	// updates which we don't simulate
	[super startUpdatingLocation];
}

-(void)stopUpdatingLocation
{
	[simTimer invalidate];
	simTimer = nil;
	
	[super stopUpdatingLocation];
}


//---------------------------------------------------------------------
// locationServicesEnabled
//---------------------------------------------------------------------
+(BOOL)locationServicesEnabled
{
	return YES;
}

//---------------------------------------------------------------------
//---------------------------------------------------------------------
// CLLocationManagerDelegate methods
//---------------------------------------------------------------------
//---------------------------------------------------------------------
- (void)locationManager:(CLLocationManager *)manager 
		 didEnterRegion:(CLRegion *)region
{
	if ([simDelegate respondsToSelector:@selector(locationManager:didEnterRegion:)])
	{
		[simDelegate locationManager:manager didEnterRegion:region];
	}
}

- (void)locationManager:(CLLocationManager *)manager 
		  didExitRegion:(CLRegion *)region
{
	if ([simDelegate respondsToSelector:@selector(locationManager:didExitRegion:)])
	{
		[simDelegate locationManager:manager didExitRegion:region];
	}
}

- (void)locationManager:(CLLocationManager *)manager 
	   didFailWithError:(NSError *)error
{
	// ignore errors from iPhone simulator
}

- (void)locationManager:(CLLocationManager *)manager 
	   didUpdateHeading:(CLHeading *)newHeading
{
	if ([simDelegate respondsToSelector:@selector(locationManager:didUpdateHeading:)])
	{
		[simDelegate locationManager:manager didUpdateHeading:newHeading];
	}
}

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation
{
	// ignore location updates from iPhone simulator
}

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
			  withError:(NSError *)error
{
	if ([simDelegate respondsToSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)])
	{
		[simDelegate locationManager:manager monitoringDidFailForRegion:region withError:error];
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
	if ([simDelegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)])
	{
		return [simDelegate locationManagerShouldDisplayHeadingCalibration:manager];
	} else {
		return NO;
	}
}

#endif

@end
