//
//  HTY360PlayerVC.h
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "HTY360Target.h"

@interface HTY360PlayerVC : UIViewController

@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) HTY360Target *currentTarget;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url;
- (CVPixelBufferRef)retrievePixelBufferToDraw;
- (void)toggleControls;
- (void)setTargetVisiblity:(BOOL)visible;
- (void)setTargetingEnabled:(BOOL)enabled;
- (void)currentTargetingAtYaw:(float)yaw andRoll:(float)roll;

@end
