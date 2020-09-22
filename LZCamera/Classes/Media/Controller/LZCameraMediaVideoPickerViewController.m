//
//  LZCameraMediaVideoPickerViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2020/9/22.
//

#import "LZCameraMediaVideoPickerViewController.h"

@interface LZCameraMediaVideoPickerViewController ()

@end

@implementation LZCameraMediaVideoPickerViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)dealloc {
    LZCameraLog();
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (UIModalTransitionStyle)modalTransitionStyle {
    return UIModalTransitionStyleCoverVertical;
}

// MARK: - Private
- (void)setupUI {
    
}

@end
