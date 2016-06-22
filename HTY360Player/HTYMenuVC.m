//
//  HTYMenuVC.m
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import "HTYMenuVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "HTY360PlayerVC.h"

@interface HTYMenuVC () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation HTYMenuVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - Button Action

- (IBAction)playDemo:(UIButton *)sender {
    [self launchVideoWithName:@"demo"];
}

- (IBAction)playOnlineURL:(UIButton *)sender {
    NSString *defaultURLString = @"http://d8d913s460fub.cloudfront.net/krpanocloud/video/airpano/video-1920x960a.mp4";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Play Online URL"
                                                                   message:@"Enter the URL"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [[NSURL alloc] initWithString:[[alert textFields] firstObject].text];
        HTY360PlayerVC *videoController = [[HTY360PlayerVC alloc] initWithNibName:@"HTY360PlayerVC"
                                                                           bundle:nil
                                                                              url:url];
        [self presentViewController:videoController animated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultURLString;
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)playFile:(UIButton *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    picker.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    picker.mediaTypes =
    [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Private Method

- (void)launchVideoWithName:(NSString*)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"m4v"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    HTY360PlayerVC *videoController = [[HTY360PlayerVC alloc] initWithNibName:@"HTY360PlayerVC"
                                                                       bundle:nil
                                                                          url:url];
    
    if (![[self presentedViewController] isBeingDismissed]) {
        [self presentViewController:videoController animated:YES completion:nil];
    }
}

- (void)openURLWithString:(NSString*)stringURL {
    NSURL *URL = [NSURL URLWithString:stringURL];
    [[UIApplication sharedApplication] openURL:URL];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
    HTY360PlayerVC *videoController = [[HTY360PlayerVC alloc] initWithNibName:@"HTY360PlayerVC"
                                                                       bundle:nil
                                                                          url:url];
    
    [self presentViewController:videoController animated:YES completion:nil];
}

@end
