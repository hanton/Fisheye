//
//  HTY360Target.h
//  HTY360Player
//
//  Created by Marco Guerrieri on 11/06/18.
//  Copyright © 2018. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface HTY360Target : NSObject

// target id if needed
@property (nonatomic, assign) int targetId;
// target name
@property (nonatomic, retain) NSString* name;
// the target center roll - REQUIRED
@property (nonatomic, assign) float roll;
// the target center yaw - REQUIRED
@property (nonatomic, assign) float yaw;
// the starting time that the target can be acquired (eg. video length of 1 minute, the target visible from second 15) - REQUIRED
@property (nonatomic, assign) double startTargetingTime;
// the starting time that the target can be acquired (eg. video length of 1 minute, the target visible until second 42) - REQUIRED
@property (nonatomic, assign) double endTargetingTime;
// the width of the target area - REQUIRED
@property (nonatomic, assign) float targetingAreaWidth;
// the height of the target area - REQUIRED
@property (nonatomic, assign) float targetingAreaHeight;

@end
