//
//  HTY360Target.m
//  HTY360Player
//
//  Created by Marco Guerrieri on 11/06/18.
//  Copyright © 2018. All rights reserved.
//

#import "HTY360Target.h"

@implementation HTY360Target

-(NSString *)description{
    return [NSString stringWithFormat:@"%@ at X:%f, Y:%f, width:%f, height:%f startTime: %f, endTime: %f", self.name, self.yaw, self.roll, self.targetingAreaWidth ,self.targetingAreaHeight, self.startTargetingTime, self.endTargetingTime];
}

@end
