//
//  LZCameraMediaModelView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaModelView.h"
#import "LZCameraCaptureProgressView.h"

@interface LZCameraMediaModelView()

@property (weak, nonatomic) IBOutlet UIView *durationContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *durationDotImgView;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@property (weak, nonatomic) IBOutlet UIButton *cancelCaptureBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishCaptureBtn;

@property (weak, nonatomic) IBOutlet UIView *captureContainerView;
@property (weak, nonatomic) IBOutlet LZCameraCaptureProgressView *captureContainerProgressView;
@property (weak, nonatomic) IBOutlet UIImageView *captureImgView;
@property (weak, nonatomic) IBOutlet UIView *captureLongVideoContainerView;
@property (weak, nonatomic) IBOutlet UIButton *captureLongVideoBtn;

@property (weak, nonatomic) UITapGestureRecognizer *stillImageSingleTap;
@property (weak, nonatomic) UILongPressGestureRecognizer *longTap;
@property (weak, nonatomic) UITapGestureRecognizer *videoSingleTap;

@end
@implementation LZCameraMediaModelView

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
	
	self.durationContainerView.hidden = YES;
	
	self.durationDotImgView.backgroundColor = [UIColor clearColor];
	UIImage *durationDodImg = [self imageInBundle:@"media_capture_reddot"];
	self.durationDotImgView.image = durationDodImg;
	
    self.cancelCaptureBtn.backgroundColor = [UIColor clearColor];
    UIImage *cancelImg = [self imageInBundle:@"media_capture_cancel"];
    [self.cancelCaptureBtn setImage:cancelImg forState:UIControlStateNormal];
	self.cancelCaptureBtn.hidden = YES;
	
	self.finishCaptureBtn.backgroundColor = [UIColor clearColor];
	UIImage *finishImg = [self imageInBundle:@"media_capture_finish"];
	[self.finishCaptureBtn setImage:finishImg forState:UIControlStateNormal];
	self.finishCaptureBtn.hidden = YES;
	
    self.captureContainerView.backgroundColor = self.captureContainerProgressView.backgroundColor;
    UIImage *captureImg = [self imageInBundle:@"media_capture_normal"];
    [self.captureImgView setImage:captureImg];
    UITapGestureRecognizer *stillImageSingleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureStillImageDidTap:)];
    [self.captureContainerView addGestureRecognizer:stillImageSingleTap];
	self.stillImageSingleTap = stillImageSingleTap;
    UILongPressGestureRecognizer *longTap =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(captureVideoDidLongTap:)];
    longTap.minimumPressDuration = 0.5f;
    [self.captureContainerView addGestureRecognizer:longTap];
	self.longTap = longTap;
    [stillImageSingleTap requireGestureRecognizerToFail:longTap];
	UITapGestureRecognizer *videoSingleTap =
	[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureVideoDidSingleTap:)];
	[self.captureContainerView addGestureRecognizer:videoSingleTap];
	self.videoSingleTap = videoSingleTap;
	
	self.captureContainerView.layer.cornerRadius = 40.0f;
    self.captureLongVideoContainerView.layer.cornerRadius = 40.0f;
}

- (void)setCaptureModel:(LZCameraCaptureModel)captureModel {
    _captureModel = captureModel;
    
    switch (captureModel) {
        case LZCameraCaptureModeStillImage: {
            
            self.stillImageSingleTap.enabled = YES;
            self.longTap.enabled = NO;
			self.videoSingleTap.enabled = NO;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelShortVideo: {
            
            self.stillImageSingleTap.enabled = NO;
            self.longTap.enabled = YES;
			self.videoSingleTap.enabled = YES;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelStillImageAndShortVideo: {
            
            self.stillImageSingleTap.enabled = YES;
            self.longTap.enabled = YES;
			self.videoSingleTap.enabled = NO;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelLongVideo: {
            
            self.stillImageSingleTap.enabled = NO;
            self.longTap.enabled = NO;
			self.videoSingleTap.enabled = NO;
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
	
	self.durationContainerView.hidden = NO;
	NSString *timeString = [NSString stringWithFormat:@"%.1f秒", curSeconds];
	self.durationLabel.text = timeString;
}

// MARK: - UI Action
- (IBAction)cancelCaptureDidClick:(UIButton *)sender {
	
	if (self.TapToCaptureVideoCancelHandler) {
		self.TapToCaptureVideoCancelHandler();
	}
	if (self.TapToCaptureVideoHandler) {
		[self stopCaptureVideo:YES];
	}
}

- (IBAction)finishCaptureDidClick:(UIButton *)sender {
	if (self.TapToCaptureVideoHandler) {
		[self stopCaptureVideo:YES];
	}
}

- (IBAction)captureLongVideoDidTouch:(UIButton *)sender {
	
    BOOL selected = self.captureLongVideoBtn.selected;
    __weak typeof(self) weakSelf = self;
    if (self.TapToCaptureVideoHandler) {
        self.TapToCaptureVideoHandler(!selected, selected, ^{
			
			typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.captureLongVideoBtn.selected = NO;
			strongSelf.captureLongVideoBtn.userInteractionEnabled = YES;
        });
    }
    self.captureLongVideoBtn.selected = !self.captureLongVideoBtn.selected;
	self.captureLongVideoBtn.userInteractionEnabled = !self.captureLongVideoBtn.selected ? NO : YES;
}

- (void)captureStillImageDidTap:(UITapGestureRecognizer *)gestureRecognizer {
    
    if (self.TapToCaptureImageHandler) {
		
        self.captureContainerView.userInteractionEnabled = NO;
        self.captureImgView.transform = CGAffineTransformMakeScale(0.8, 0.8);
		__weak typeof(self) weakSelf = self;
        self.TapToCaptureImageHandler(^{
			
			typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.captureContainerView.userInteractionEnabled = YES;
            strongSelf.captureImgView.transform = CGAffineTransformIdentity;
        });
    }
}

- (void)captureVideoDidLongTap:(UILongPressGestureRecognizer *)gestureRecognizer {
	
    if (self.TapToCaptureVideoHandler) {
		
        self.captureImgView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
		BOOL end = NO;
		if (self.captureModel == LZCameraCaptureModelStillImageAndShortVideo || self.maxDuration <= 15) {
			
			UIGestureRecognizerState state = gestureRecognizer.state;
			// BOOL begin = state == UIGestureRecognizerStateBegan;
			end = state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateFailed || state == UIGestureRecognizerStateCancelled;
		} else {
			
			self.cancelCaptureBtn.hidden = NO;
			self.finishCaptureBtn.hidden = NO;
		}
		self.captureContainerView.userInteractionEnabled = end ? NO : YES;
		[self stopCaptureVideo:end];
    }
}

- (void)captureVideoDidSingleTap:(UITapGestureRecognizer *)gestureRecognizer {
	if (self.TapToCaptureVideoHandler) {
		[self stopCaptureVideo:YES];
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

/**
 停止录制视频

 @param stop 是否停止
 */
- (void)stopCaptureVideo:(BOOL)stop {
	
	__weak typeof(self) weakSelf = self;
	self.TapToCaptureVideoHandler(!stop, stop, ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf.captureContainerProgressView clearProgress];
		self.cancelCaptureBtn.hidden = YES;
		self.finishCaptureBtn.hidden = YES;
		self.durationContainerView.hidden = YES;
		strongSelf.captureImgView.transform = CGAffineTransformIdentity;
		strongSelf.captureContainerView.userInteractionEnabled = YES;
	});
}

@end
