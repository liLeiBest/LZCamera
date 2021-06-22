//
//  LZCameraMediaVideoPickerViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2020/9/22.
//

#import "LZCameraMediaVideoPickerViewController.h"

@interface LZCameraMediaVideoPickerViewController ()

@property (nonatomic, weak) UIView *cover;

@end

@implementation LZCameraMediaVideoPickerViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.cover.frame = self.view.bounds;
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

// MARK: - Public
- (void)removeCover {
    [UIView animateWithDuration:0.25 animations:^{
        self.cover.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.cover removeFromSuperview];
    }];
}

// MARK: - Private
- (void)setupUI {
    
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    self.cover = view;
}

@end
