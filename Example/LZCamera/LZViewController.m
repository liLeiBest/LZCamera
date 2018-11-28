//
//  LZViewController.m
//  LZCamera
//
//  Created by lilei_hapy@163.com on 11/15/2018.
//  Copyright (c) 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZViewController.h"
#import "LZTestViewController.h"
#import <LZCamera/LZCameraMedia.h>

@interface LZViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
}

// MARK: - UI Action
- (IBAction)leftDidClick:(id)sender {
    
}

- (IBAction)rightDidClick:(id)sender {
    
    LZCameraMediaViewController *ctr = [LZCameraMediaViewController instance];
    ctr.captureModel = LZCameraCaptureModelStillImageAndShortVideo;
//    ctr.showStatusBar = NO;
    ctr.CameraImageCompletionHandler = ^(UIImage * _Nonnull stillImage) {
        self.previewImgView.image = stillImage;
    };
    ctr.CameraVideoCompletionHandler = ^(UIImage * _Nonnull thumbnailImage, NSURL * _Nonnull videoURL) {
        self.previewImgView.image = thumbnailImage;
    };
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

// MARK: - Private


@end
