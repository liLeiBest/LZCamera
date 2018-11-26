//
//  LZCameraMediaStatusView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaStatusView.h"


@implementation LZCameraMediaStatusView {
    IBOutlet UIButton *flashlightBtn;
    IBOutlet UIButton *switchCameraBtn;
    IBOutlet UILabel *durationTimeLab;
}

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
    
    flashlightBtn.backgroundColor = [UIColor clearColor];
    switchCameraBtn.backgroundColor = [UIColor clearColor];
    UIImage *flashlightImg = [self imageInBundle:@"media_flashlight_auto"];
    [flashlightBtn setImage:flashlightImg forState:UIControlStateNormal];
    UIImage *switchCameraImg = [self imageInBundle:@"media_camera_switch"];
    [switchCameraBtn setImage:switchCameraImg forState:UIControlStateNormal];
    [self updateDurationTime:kCMTimeZero show:NO];
}

// MARK: - UI Action
- (IBAction)flashlightDidTap:(UIButton *)sender {
    if (self.TapToFlashModelHandler) {
        self.TapToFlashModelHandler(1);
    }
}

- (IBAction)switchCameraDidTap:(UIButton *)sender {
    if (self.TapToSwitchCameraHandler) {
        self.TapToSwitchCameraHandler();
    }
}

// MARK: - Public
- (void)updateFlashVisualState:(LZFlashVisualState)state {
    flashlightBtn.hidden = state == LZFlashVisualStateOff;
}

- (void)updateDurationTime:(CMTime)durationTime show:(BOOL)show {
    
    durationTimeLab.hidden = show ? NO : YES;
    NSUInteger time = (NSUInteger)CMTimeGetSeconds(durationTime);
    NSInteger hours = (time / 3600);
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    
    NSString *format = @"%02i:%02i:%02i";
    NSString *timeString = [NSString stringWithFormat:format, hours, minutes, seconds];
    durationTimeLab.text = timeString;
}

// MARK: - Private
/**
 加载图片资源

 @param imageName 图片名称
 @return UIImage
 */
- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

@end
