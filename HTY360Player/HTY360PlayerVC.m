//
//  HTY360PlayerVC.m
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import "HTY360PlayerVC.h"
#import "HTYGLKVC.h"

#define ONE_FRAME_DURATION 0.033
#define ES_PI  (3.14159265f)
#define HIDE_CONTROL_DELAY 3.0
#define DEFAULT_VIEW_ALPHA 0.6

NSString * const kTracksKey = @"tracks";
NSString * const kPlayableKey = @"playable";
NSString * const kRateKey = @"rate";
NSString * const kCurrentItemKey = @"currentItem";
NSString * const kStatusKey = @"status";

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface HTY360PlayerVC ()


@property (strong, nonatomic) IBOutlet UIView *playerControlBackgroundView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISlider *progressSlider;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *gyroButton;
@property (strong, nonatomic) HTYGLKVC *glkViewController;
@property (strong, nonatomic) AVPlayerItemVideoOutput* videoOutput;
@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerItem* playerItem;
@property (strong, nonatomic) id timeObserver;
@property (assign, nonatomic) CGFloat mRestoreAfterScrubbingRate;
@property (assign, nonatomic) BOOL seekToZeroBeforePlay;

@property (weak, nonatomic) IBOutlet UIImageView *targetImageView;
@property (assign, nonatomic) BOOL canTargeting;
@property (weak, nonatomic) IBOutlet UIView *currentYawAndRollView;
@property (weak, nonatomic) IBOutlet UILabel *currentYawLbl;
@property (weak, nonatomic) IBOutlet UILabel *currentRollLbl;
@property (weak, nonatomic) IBOutlet UILabel *targetAcquireLbl;

@end

@implementation HTY360PlayerVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setVideoURL:url];
    }
    return self;
}


- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self setupVideoPlaybackForURL:_videoURL];
    [self configureGLKView];
    [self configurePlayButton];
    [self configureProgressSlider];
    [self configureControleBackgroundView];
    [self configureBackButton];
    [self configureGyroButton];
    [self createTarget];
    
#if SHOW_DEBUG_LABEL
    self.debugView.hidden = NO;
#endif
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self pause];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self updatePlayButton];
    [self.player seekToTime:[self.player currentTime]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.playerControlBackgroundView = nil;
    self.playButton = nil;
    self.progressSlider = nil;
    self.backButton = nil;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    @try {
        [self removePlayerTimeObserver];
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
        [self.playerItem removeOutput:self.videoOutput];
        [self.player removeObserver:self forKeyPath:kCurrentItemKey];
        [self.player removeObserver:self forKeyPath:kRateKey];
    } @catch(id anException) {
        //do nothing
    }
    
    self.videoOutput = nil;
    self.playerItem = nil;
    self.player = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self updatePlayButton];
}

#pragma mark - video communication

- (CVPixelBufferRef)retrievePixelBufferToDraw {
    CVPixelBufferRef pixelBuffer = [self.videoOutput copyPixelBufferForItemTime:[self.playerItem currentTime] itemTimeForDisplay:nil];
    return pixelBuffer;
}

#pragma mark - video setting

- (void)setupVideoPlaybackForURL:(NSURL*)url {
    NSDictionary *pixelBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffAttributes];
    
    self.player = [[AVPlayer alloc] init];
    
    // Do not take mute button into account
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                          error:&error];
    if (!success) {
        NSLog(@"Could not use AVAudioSessionCategoryPlayback", nil);
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[[asset URL] path]]) {
        //NSLog(@"file does not exist");
    }
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        
        dispatch_async( dispatch_get_main_queue(),
                       ^{
                           /* Make sure that the value of each key has loaded successfully. */
                           for (NSString *thisKey in requestedKeys) {
                               NSError *error = nil;
                               AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
                               if (keyStatus == AVKeyValueStatusFailed) {
                                   [self assetFailedToPrepareForPlayback:error];
                                   return;
                               }
                           }
                           
                           NSError* error = nil;
                           AVKeyValueStatus status = [asset statusOfValueForKey:kTracksKey error:&error];
                           if (status == AVKeyValueStatusLoaded) {
                               self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                               [self.playerItem addOutput:self.videoOutput];
                               [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                               [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
                               
                               /* When the player item has played to its end time we'll toggle
                                the movie controller Pause button to be the Play button */
                               [[NSNotificationCenter defaultCenter] addObserver:self
                                                                        selector:@selector(playerItemDidReachEnd:)
                                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                                          object:self.playerItem];
                               
                               self.seekToZeroBeforePlay = NO;
                               
                               [self.playerItem addObserver:self
                                                 forKeyPath:kStatusKey
                                                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                    context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
                               
                               [self.player addObserver:self
                                             forKeyPath:kCurrentItemKey
                                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
                               
                               [self.player addObserver:self
                                             forKeyPath:kRateKey
                                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
                               
                               
                               [self initScrubberTimer];
                               [self syncScrubber];
                           } else {
                               NSLog(@"%@ Failed to load the tracks.", self);
                           }
                       });
    }];
}

#pragma mark - rendering glk view management

- (void)configureGLKView {
    self.glkViewController = [[HTYGLKVC alloc] init];
    self.glkViewController.videoPlayerController = self;
    self.glkViewController.view.frame = self.view.bounds;
    [self.view insertSubview:self.glkViewController.view belowSubview:self.playerControlBackgroundView];
    [self addChildViewController:self.glkViewController];
    [self.glkViewController didMoveToParentViewController:self];
}

#pragma mark - play button management

- (void)configurePlayButton{
    self.playButton.backgroundColor = [UIColor clearColor];
    self.playButton.showsTouchWhenHighlighted = YES;
    
    [self disablePlayerButtons];
    [self updatePlayButton];
}

- (IBAction)playButtonTouched:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ([self isPlaying]) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)updatePlayButton {
    [self.playButton setImage:[UIImage imageNamed:[self isPlaying] ? @"playback_pause" : @"playback_play"]
                     forState:UIControlStateNormal];
}

- (void)play {
    if ([self isPlaying])
        return;
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
    if (YES == self.seekToZeroBeforePlay) {
        self.seekToZeroBeforePlay = NO;
        [self.player seekToTime:kCMTimeZero];
    }
    
    [self updatePlayButton];
    [self.player play];
    
    [self scheduleHideControls];
}

- (void)pause {
    if (![self isPlaying])
        return;
    
    [self updatePlayButton];
    [self.player pause];
    
    [self scheduleHideControls];
}

#pragma mark - progress slider management

- (void)configureProgressSlider {
    self.progressSlider.continuous = NO;
    self.progressSlider.value = 0;
    
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateNormal];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateHighlighted];
}

#pragma mark - back and gyro button management

- (void)configureBackButton {
    self.backButton.backgroundColor = [UIColor clearColor];
    self.backButton.showsTouchWhenHighlighted = YES;
}

- (void)configureGyroButton {
    self.gyroButton.backgroundColor = [UIColor clearColor];
    self.gyroButton.showsTouchWhenHighlighted = YES;
}

#pragma mark - controls management

- (void)enablePlayerButtons {
    self.playButton.enabled = YES;
}

- (void)disablePlayerButtons {
    self.playButton.enabled = NO;
}

- (void)configureControleBackgroundView {
    self.playerControlBackgroundView.layer.cornerRadius = 8;
}

- (void)toggleControls {
    if(self.playerControlBackgroundView.hidden){
        [self showControlsFast];
    }else{
        [self hideControlsFast];
    }
    
    [self scheduleHideControls];
}

- (void)scheduleHideControls {
    if(!self.playerControlBackgroundView.hidden) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hideControlsSlowly) withObject:nil afterDelay:HIDE_CONTROL_DELAY];
    }
}

// Hide or show the target image, the target acquire label and the current yaw and roll view
- (void)setTargetVisiblity:(BOOL)visible {
    [self.targetImageView setHidden:!visible];
    [self.currentYawAndRollView setHidden:!visible];
}

//  Enable or disable the targeting function (set canTargeting boolean)
- (void)setTargetingEnabled:(BOOL)enabled {
    self.canTargeting = enabled;
}

- (void)hideControlsWithDuration:(NSTimeInterval)duration {
    self.playerControlBackgroundView.alpha = DEFAULT_VIEW_ALPHA;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void) {
                         self.playerControlBackgroundView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         if(finished)
                             self.playerControlBackgroundView.hidden = YES;
                     }];
    
}

- (void)hideControlsFast {
    [self hideControlsWithDuration:0.2];
}

- (void)hideControlsSlowly {
    [self hideControlsWithDuration:1.0];
}

- (void)showControlsFast {
    self.playerControlBackgroundView.alpha = 0.0;
    self.playerControlBackgroundView.hidden = NO;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void) {
                         self.playerControlBackgroundView.alpha = DEFAULT_VIEW_ALPHA;
                     }
                     completion:nil];
}

- (void)removeTimeObserverForPlayer {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

#pragma mark - slider progress management

- (void)initScrubberTimer {
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
        interval = 0.5f * duration / width;
    }
    
    __weak HTY360PlayerVC* weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                         /* If you pass NULL, the main queue is used. */
                                                                  queue:NULL
                                                             usingBlock:^(CMTime time) {
                                                                 [weakSelf syncScrubber];
                                                             }];
    
}

- (CMTime)playerItemDuration {
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
        return ([self.playerItem duration]);
    }
    
    return (kCMTimeInvalid);
}

- (void)syncScrubber {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        
        [self.progressSlider setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender {
    self.mRestoreAfterScrubbingRate = [self.player rate];
    [self.player setRate:0.f];
    
    /* Remove previous timer. */
    [self removeTimeObserverForPlayer];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender {
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        }
    }
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender {
    if (!self.timeObserver) {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
            double tolerance = 0.5f * duration / width;
            
            __weak HTY360PlayerVC* weakSelf = self;
            self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                                                                          queue:NULL
                                                                     usingBlock:^(CMTime time) {
                                                                         [weakSelf syncScrubber];
                                                                     }];
        }
    }
    
    if (self.mRestoreAfterScrubbingRate) {
        [self.player setRate:self.mRestoreAfterScrubbingRate];
        self.mRestoreAfterScrubbingRate = 0.f;
    }
}

- (BOOL)isScrubbing {
    return self.mRestoreAfterScrubbingRate != 0.f;
}

- (void)enableScrubber {
    self.progressSlider.enabled = YES;
}

- (void)disableScrubber {
    self.progressSlider.enabled = NO;
}

- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    /* AVPlayerItem "status" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext) {
        [self updatePlayButton];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown: {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                [self disableScrubber];
                [self disablePlayerButtons];
                break;
            }
            case AVPlayerStatusReadyToPlay: {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                [self initScrubberTimer];
                [self enableScrubber];
                [self enablePlayerButtons];
                break;
            }
            case AVPlayerStatusFailed: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
                NSLog(@"Error fail : %@", playerItem.error);
                break;
            }
        }
    } else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext) {
        [self updatePlayButton];
        // NSLog(@"AVPlayerDemoPlaybackViewControllerRateObservationContext");
    } else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext) {
        /* AVPlayer "currentItem" property observer.
         Called when the AVPlayer replaceCurrentItemWithPlayerItem:
         replacement will/did occur. */
        
        //NSLog(@"AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext");
    } else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

- (void)assetFailedToPrepareForPlayback:(NSError *)error {
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:[error localizedDescription]
                                          message:[error localizedFailureReason]
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK action");
                               }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)isPlaying {
    return self.mRestoreAfterScrubbingRate != 0.f || [self.player rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    /* After the movie has played to its end time, seek back to time zero
     to play it again. */
    self.seekToZeroBeforePlay = YES;
}

#pragma mark - gyro button

- (IBAction)gyroButtonTouched:(id)sender {
    if(self.glkViewController.isUsingMotion) {
        [self.glkViewController stopDeviceMotion];
    } else {
        [self.glkViewController startDeviceMotion];
    }
    
    self.gyroButton.selected = self.glkViewController.isUsingMotion;
}

#pragma mark - back button

- (IBAction)backButtonTouched:(id)sender {
    [self removePlayerTimeObserver];
    
    [self.player pause];
    
    [self.glkViewController removeFromParentViewController];
    self.glkViewController = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/* Cancels the previously registered time observer. */
- (void)removePlayerTimeObserver {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

// method called by HTYGLKVC for check if the user is acquiring a target passng yaw and roll
- (void)currentTargetingAtYaw:(float)yaw andRoll:(float)roll {
    [self.currentYawLbl setText:[NSString stringWithFormat:@"%f", yaw]];
    [self.currentRollLbl setText:[NSString stringWithFormat:@"%f", roll]];
    
    if(self.currentTarget == nil || !self.canTargeting){
        return;
    }

    float currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
    if(self.currentTarget.startTargetingTime <= currentTime && self.currentTarget.endTargetingTime >= currentTime){
        float halfSideWidth = self.currentTarget.targetingAreaWidth/2;
        float halfSideHeight = self.currentTarget.targetingAreaHeight/2;
        
        float targetX = _currentTarget.yaw;
        float targetY = _currentTarget.roll;
        
        float areaX0 = targetX - halfSideWidth;
        float areaY0 = targetY - halfSideHeight;
        
        CGRect area = CGRectMake(areaX0 , areaY0, self.currentTarget.targetingAreaWidth, self.currentTarget.targetingAreaHeight);
        CGPoint point = CGPointMake(yaw, roll);
        
        if(CGRectContainsPoint(area, point)){
            [self onTargetAcquired:self.currentTarget];
            return;
        }
        
        if(targetX>0 && (targetX+halfSideWidth)>ES_PI){
            area = CGRectMake((areaX0-2*ES_PI), areaY0, self.currentTarget.targetingAreaWidth, self.currentTarget.targetingAreaHeight);
            if(CGRectContainsPoint(area, point)){
                [self onTargetAcquired:self.currentTarget];
                return;
            }
        }
        else if(targetX<0 && (targetX-halfSideWidth)<-ES_PI){
            area = CGRectMake(areaX0+(2*ES_PI), areaY0, self.currentTarget.targetingAreaWidth, self.currentTarget.targetingAreaHeight);
            if(CGRectContainsPoint(area, point)){
                [self onTargetAcquired:self.currentTarget];
                return;
            }
        }
        [self.targetAcquireLbl setHidden:YES];
    }
}

// called when a target is acquired
- (void)onTargetAcquired:(HTY360Target*)target {
    if (self.canTargeting) {
        NSLog(@"ACQUIRED TARGET %d (%@)", target.targetId, target.name);
        [self.targetAcquireLbl setHidden:NO];
    }
}


// method for demo, create a target in front of the video (looking straight where the camera is walking)
- (void)createTarget {
    [self setTargetingEnabled:YES];
    HTY360Target* target = [HTY360Target new];
    target.targetId = 1;
    target.name = @"Test";
    target.yaw = 1.383375;
    target.roll = -0.117379;
    target.startTargetingTime = 1;
    target.endTargetingTime = 40;
    target.targetingAreaHeight = 0.40;
    target.targetingAreaWidth = 0.2;
    self.currentTarget = target;
}

@end
