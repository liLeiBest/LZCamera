//
//  LZViewController.m
//  LZCamera
//
//  Created by lilei_hapy@163.com on 11/15/2018.
//  Copyright (c) 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZViewController.h"
#import <LZCamera/LZCameraMedia.h>

@interface LZViewController ()

@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
}

// MARK: - UI Action
- (IBAction)testDidClick:(id)sender {
    
    LZCameraMediaViewController *ctr = [LZCameraMediaViewController instance];
    ctr.captureModel = LZCameraCaptureModelStillImageAndShortVideo;
    ctr.detectFaces = YES;
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

// MARK: - Private


@end
