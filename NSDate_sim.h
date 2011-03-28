//-----------------------------------------------------------------------------
//  NSDate_sim.h
//
// This class is used for testing when you need to simulate that your app is
// running at a specific date/time in the past or future.  Also allows you 
// to specific that time passes faster/slower.
// 
// For example: so you can watch your app's behavior for 24 hours
// in only 24 minutes (at 60x).
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

#import <Foundation/Foundation.h>

@interface NSDate_sim : NSObject {
	float clockSpeed;			// defaults to 1.0
	NSTimeInterval clockStart;	// time/date that clock was initialized
	NSTimeInterval offset;		// time/date offset from real time
}

-(id)init;

//----------------------------------------------------------------------------
// Set clock back to real date/time, normal speed
//----------------------------------------------------------------------------
-(void)normalize;

//----------------------------------------------------------------------------
// Use this instead of [NSDate date] for testing
//----------------------------------------------------------------------------
-(NSDate*)date;		// returns current date/time, offset for testing purposes

//----------------------------------------------------------------------------
// Sets the date/time in the simulator
//----------------------------------------------------------------------------
-(void)setDateYear:(int)year Month:(int)month Day:(int)day Hour:(int)hour Minute:(int)min Second:(int)sec;

@property (assign, nonatomic) float clockSpeed;     // set the clock speed factor

@end
