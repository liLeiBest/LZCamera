//
//  LZCameraMediaModelView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaModelView.h"
#import "LZCameraCaptureProgressView.h"

@interface LZCameraMediaModelView()

@property (weak, nonatomic) IBOutlet UIButton *cancleCaptureBtn;
@property (weak, nonatomic) IBOutlet UIView *captureContainerView;
@property (weak, nonatomic) IBOutlet LZCameraCaptureProgressView *captureContainerProgressView;
@property (weak, nonatomic) IBOutlet UIImageView *captureImgView;
@property (weak, nonatomic) IBOutlet UIView *captureLongVideoContainerView;
@property (weak, nonatomic) IBOutlet UIButton *captureLongVideoBtn;

@property (weak, nonatomic) UITapGestureRecognizer *singleTap;
@property (weak, nonatomic) UILongPressGestureRecognizer *longTap;

@end
@implementation LZCameraMediaModelView

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.cancleCaptureBtn.backgroundColor = [UIColor clearColor];
    UIImage *cancelImg = [self imageInBundle:@"media_capture_cancel"];
    [self.cancleCaptureBtn setImage:cancelImg forState:UIControlStateNormal];
	
    self.captureContainerView.backgroundColor = self.captureContainerProgressView.backgroundColor;
    UIImage *captureImg = [self imageInBundle:@"media_capture_normal"];
    [self.captureImgView setImage:captureImg];
    UITapGestureRecognizer *singleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureStillImageDidTap:)];
    [self.captureContainerView addGestureRecognizer:singleTap];
	self.singleTap = singleTap;
    UILongPressGestureRecognizer *longTap =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(captureVideoDidTap:)];
    longTap.minimumPressDuration = 0.5f;
    [self.captureContainerView addGestureRecognizer:longTap];
	self.longTap = longTap;
    [singleTap requireGestureRecognizerToFail:longTap];
	
	self.captureContainerView.layer.cornerRadius = 40.0f;
    self.captureLongVideoContainerView.layer.cornerRadius = 40.0f;
}

- (void)setCaptureModel:(LZCameraCaptureModel)captureModel {
    _captureModel = captureModel;
    
    switch (captureModel) {
        case LZCameraCaptureModeStillImage: {
            
            self.singleTap.enabled = YES;
            self.longTap.enabled = NO;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelShortVideo: {
            
            self.singleTap.enabled = NO;
            self.longTap.enabled = YES;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelStillImageAndShortVideo: {
            
            self.singleTap.enabled = YES;
            self.longTap.enabled = YES;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelLongVideo: {
            
            self.singleTap.enabled = NO;
            self.longTap.enabled = NO;
            self.captureContainerView.hidden = YES;
            self.captureLongVideoContainerView.hidden = NO;
        }
            break;
        default:
            break;
    }
}

// MARK: - Public
- (void)updateDurationTime:(CMTime)durationTime {
    
    Float64 curSeconds = CMTimeGetSeconds(durationTime);
    self.captureContainerProgressView.progressValue = curSeconds / self.maxDuration;
}

// MARK: - UI Action
- (IBAction)cancelDidTap:(UIButton *)sender {
    if (self.TapToCancelCaptureHandler) {
        self.TapToCancelCaptureHandler();
    }
}

- (IBAction)captureLongVideoDidTouch:(UIButton *)sender {
    
    self.cancleCaptureBtn.hidden = YES;
    BOOL selected = self.captureLongVideoBtn.selected;
    __weak typeof(self) weakSelf = self;
    if (self.TapToCaptureVideoHandler) {
        self.TapToCaptureVideoHandler(!selected, selected, ^{
			
			typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.cancleCaptureBtn.hidden = NO;
			strongSelf.captureLongVideoBtn.userInteractionEnabled = YES;
        });
    }
    self.captureLongVideoBtn.selected = !self.captureLongVideoBtn.selected;
	self.captureLongVideoBtn.userInteractionEnabled = !self.captureLongVideoBtn.selected ? NO : YES;
}

- (void)captureStillImageDidTap:(UITapGestureRecognizer *)gestureRecognizer {
    
    if (self.TapToCaptureImageHandler) {
        
        self.cancleCaptureBtn.hidden = YES;
        self.captureContainerView.userInteractionEnabled = NO;
        self.captureImgView.transform = CGAffineTransformMakeScale(0.8, 0.8);
		__weak typeof(self) weakSelf = self;
        self.TapToCaptureImageHandler(^{
			
			typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.cancleCaptureBtn.hidden = NO;
            strongSelf.captureContainerView.userInteractionEnabled = YES;
            strongSelf.captureImgView.transform = CGAffineTransformIdentity;
        });
    }
}

- (void)captureVideoDidTap:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (self.TapToCaptureVideoHandler) {
        
        self.cancleCaptureBtn.hidden = YES;
        self.captureImgView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
        UIGestureRecognizerState state = gestureRecognizer.state;
		BOOL begin = state == UIGestureRecognizerStateBegan;
		BOOL end = state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateFailed || state == UIGestureRecognizerStateCancelled;
		self.captureContainerView.userInteractionEnabled = end ? NO : YES;
		
		__weak typeof(self) weakSelf = self;
        self.TapToCaptureVideoHandler(begin, end, ^{
			
			typeof(weakSelf) strongSelf = weakSelf;
			[strongSelf.captureContainerProgressView clearProgress];
            strongSelf.cancleCaptureBtn.hidden = NO;
            strongSelf.captureImgView.transform = CGAffineTransformIdentity;
			strongSelf.captureContainerView.userInteractionEnabled = YES;
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
