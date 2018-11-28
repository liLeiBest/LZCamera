//
//  LZCameraMediaStatusView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaStatusView.h"
#import "LZCameraCaptureFlashControl.h"

@implementation LZCameraMediaStatusView {
    IBOutlet LZCameraCaptureFlashControl *flashlightControl;
    IBOutlet UIButton *switchCameraBtn;
    IBOutlet UILabel *durationTimeLab;
}

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
    
    switchCameraBtn.backgroundColor = [UIColor clearColor];
    UIImage *switchCameraImg = [self imageInBundle:@"media_camera_switch"];
    [switchCameraBtn setImage:switchCameraImg forState:UIControlStateNormal];
	
}

- (void)setCaptureModel:(LZCameraCaptureModel)captureModel {
    _captureModel = captureModel;
    
    durationTimeLab.hidden = captureModel != LZCameraCaptureModelLongVideo;
}

- (void)setTapToFlashModelHandler:(void (^)(LZCameraFlashMode))TapToFlashModelHandler {
	_TapToFlashModelHandler = TapToFlashModelHandler;
	
	flashlightControl.TapToFlashModeHandler = TapToFlashModelHandler;
}

// MARK: - Public
- (void)updateFlashVisualState:(LZFlashVisualState)state {
    flashlightControl.hidden = state == LZFlashVisualStateOff;
}

- (void)updateDurationTime:(CMTime)durationTime {
    
    durationTimeLab.hidden = self.captureModel == LZCameraCaptureModelLongVideo ? NO : YES;
    NSUInteger time = (NSUInteger)CMTimeGetSeconds(durationTime);
    NSInteger hours = (time / 3600);
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    
    NSString *format = @"%02i:%02i:%02i";
    NSString *timeString = [NSString stringWithFormat:format, hours, minutes, seconds];
    durationTimeLab.text = timeString;
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
