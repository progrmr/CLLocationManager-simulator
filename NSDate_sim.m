//-----------------------------------------------------------------------------
//  NSDate_sim.h
//
//  Created by Gary A. Morris on 2/15/11.
//----------------------------------------------------------------------------
//
//  Copyright 2011 Gary A. Morris.  http://mggm.net
//
//  This file is part of NSDate_sim.
//
//  NSDate_sim is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  NSDate_sim is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//  
//  You should have received a copy of the GNU Lesser General Public License
//  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
//-----------------------------------------------------------------------------

#import "NSDate_sim.h"

@implementation NSDate_sim

@synthesize clockSpeed;

//----------------------------------------------------------------------------
// set clock back to real date/time, normal speed
//----------------------------------------------------------------------------
-(void)normalize;
{
	clockSpeed = 1.0f;
	offset	   = 0;
	clockStart = [NSDate timeIntervalSinceReferenceDate];
}

-(id)init
{
    if( (self = [super init]) ) { 
		[self normalize];
    }
    return self;
}


//----------------------------------------------------------------------------
// use this instead of [NSDate date] for testing
//----------------------------------------------------------------------------
-(NSDate*)date
{
	// How long has elapsed since we started our test clock?
	NSTimeInterval timeSinceClockStart = [NSDate timeIntervalSinceReferenceDate] - clockStart;
	
	// Adjust elapsed time by the clock speed
	timeSinceClockStart *= clockSpeed;
	
	// Calculate current time now (rel to RefDate), including offset and speed
	NSTimeInterval timeSinceRef = clockStart + offset + timeSinceClockStart;

	// adjust the current time with the offset
	NSDate* result = [NSDate dateWithTimeIntervalSinceReferenceDate:timeSinceRef];
	
#if 0
	// Extract the time from the time components
	int units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *dComps = [[NSCalendar currentCalendar] components:units fromDate:result];
	const int hour    = [dComps hour];
	const int minute  = [dComps minute];
	const int second  = [dComps second];	
	const int month   = [dComps month];
	const int day     = [dComps day];
	const int year    = [dComps year];
	NSLog(@"date=%4d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second);	
#endif
	
	return result;
}


//-------------------------------------------------------------------
// Sets the date/time in the simulator
//
// Set the offset by calculating interval from now to the specified date/time
//-------------------------------------------------------------------
-(void)setDateYear:(int)year Month:(int)month Day:(int)day Hour:(int)hour Minute:(int)min Second:(int)sec
{
	// create an NSDate given the specified time
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setDay  :day];
	[comps setMonth:month];
	[comps setYear :year];
	[comps setHour :hour];
	[comps setMinute:min];
	[comps setSecond:sec];
	NSDate* testDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
	[comps release];
	
	NSTimeInterval testTimeSinceRef = [testDate timeIntervalSinceReferenceDate];
	
	// Keep the time that the test clock started as an interval from the RefDate
	clockStart = [NSDate timeIntervalSinceReferenceDate];
		
	// Save the off from the clockStart time to the test time specified
	offset = testTimeSinceRef - clockStart;
}


@end
