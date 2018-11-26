//
//  LZCameraMediaModelView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaModelView.h"
#import "LZCameraCaptureProgressView.h"

@implementation LZCameraMediaModelView {
    IBOutlet UIButton *cancleCaptureBtn;
    IBOutlet LZCameraCaptureProgressView *captureContainerView;
    IBOutlet UIImageView *captureImgView;
    IBOutlet UIButton *captureBtn;
    
    UITapGestureRecognizer *singleTap;
    UILongPressGestureRecognizer *longTap;
}

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
    
    cancleCaptureBtn.backgroundColor = [UIColor clearColor];
    UIImage *cancelImg = [self imageInBundle:@"media_capture_cancel"];
    [cancleCaptureBtn setImage:cancelImg forState:UIControlStateNormal];
    
    UIImage *captureImg = [self imageInBundle:@"media_capture_normal"];
    [captureImgView setImage:captureImg];
    captureContainerView.layer.cornerRadius = 40.0f;
    singleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureStillImageDidTap:)];
    [captureContainerView addGestureRecognizer:singleTap];
    longTap =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(captureVideoDidTap:)];
    longTap.minimumPressDuration = 0.5f;
    [captureContainerView addGestureRecognizer:longTap];
    [singleTap requireGestureRecognizerToFail:longTap];
    
    captureBtn.hidden = YES;
}

- (void)setCaptureModel:(LZCameraCaptureModel)captureModel {
    _captureModel = captureModel;
    
    switch (captureModel) {
        case LZCameraCaptureModeStillImage: {
            
            singleTap.enabled = YES;
            longTap.enabled = NO;
            captureBtn.hidden = YES;
        }
            break;
        case LZCameraCaptureModelShortVideo: {
            
            singleTap.enabled = NO;
            longTap.enabled = YES;
            captureBtn.hidden = YES;
        }
            break;
        case LZCameraCaptureModelStillImageAndShortVideo: {
            
            singleTap.enabled = YES;
            longTap.enabled = YES;
            captureBtn.hidden = YES;
        }
            break;
        case LZCameraCaptureModelLongVideo: {
            
            singleTap.enabled = NO;
            longTap.enabled = NO;
            captureBtn.hidden = NO;
        }
            break;
        default:
            break;
    }
}

- (void)setMaxDuration:(NSInteger)maxDuration {
    _maxDuration = maxDuration;
    
    captureContainerView.timeMax = 10;
}

// MARK: - UI Action
- (IBAction)cancelDidTap:(UIButton *)sender {
    if (self.TapToCancelCaptureHandler) {
        self.TapToCancelCaptureHandler();
    }
}

- (IBAction)captureLongVideoDidTouch:(UIButton *)sender {
    
    BOOL selected = sender.selected;
    if (self.TapToCaptureVideoHandler) {
        self.TapToCaptureVideoHandler(!selected, selected, ^{});
    }
    sender.selected = !sender.selected;
}

- (void)captureStillImageDidTap:(UITapGestureRecognizer *)gestureRecognizer {
    
    if (self.TapToCaptureImageHandler) {
        
        captureContainerView.userInteractionEnabled = NO;
        __weak typeof(captureContainerView) weakCaptureContainerView = captureContainerView;
        self.TapToCaptureImageHandler(^{
            weakCaptureContainerView.userInteractionEnabled = YES;
        });
    }
}

- (void)captureVideoDidTap:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (self.TapToCaptureVideoHandler) {
        self.TapToCaptureVideoHandler(gestureRecognizer.state == UIGestureRecognizerStateBegan, gestureRecognizer.state == UIGestureRecognizerStateEnded, ^{
            
        });
    }
}

// MARK: - Private
/**
 加载图片资源
 
 @param imageName NSString
 @return UIImage
 */
- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

@end
