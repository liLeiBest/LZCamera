//
//  LZViewController.m
//  LZCamera
//
//  Created by lilei_hapy@163.com on 11/15/2018.
//  Copyright (c) 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZViewController.h"
#import "LZPreviewViewController.h"
#import <LZCamera/LZCameraMedia.h>

@interface LZViewController ()

@property (weak, nonatomic) IBOutlet LZCameraMediaPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UIPinchGestureRecognizer *pichGestureRecognizer;
@property (strong, nonatomic) LZCameraController *cameraController;

@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
    NSError *error;
    if (!error) {
        
        __weak typeof(self) weakSelf = self;
        self.cameraController.zoomCompletionHandler = ^(CGFloat zoomValue) {
            weakSelf.zoomSlider.value = zoomValue;
        };
    }
}

// MARK: - UI Action
- (IBAction)testDidClick:(id)sender {
    
    LZCameraMediaViewController *ctr = [LZCameraMediaViewController instance];
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

// MARK: - Private


@end
