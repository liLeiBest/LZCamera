//
//  LZCameraMediaModelView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaModelView.h"
#import "LZCameraCaptureProgressView.h"

@interface LZCameraMediaModelView()

@property (weak, nonatomic) IBOutlet UIButton *albumVideoBtn;

@property (weak, nonatomic) IBOutlet UIView *durationContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *durationDotImgView;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@property (weak, nonatomic) IBOutlet UIView *captureContainerView;
@property (weak, nonatomic) IBOutlet LZCameraCaptureProgressView *captureContainerProgressView;
@property (weak, nonatomic) IBOutlet UIImageView *captureImgView;
@property (weak, nonatomic) IBOutlet UIView *captureLongVideoContainerView;
@property (weak, nonatomic) IBOutlet UIButton *captureLongVideoBtn;

@property (weak, nonatomic) UITapGestureRecognizer *stillImageSingleTap;
@property (weak, nonatomic) UILongPressGestureRecognizer *longTap;
@property (weak, nonatomic) UITapGestureRecognizer *videoSingleTap;
@property (assign, nonatomic, getter=isRecording) BOOL recording;

@end
@implementation LZCameraMediaModelView

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
	
	self.albumVideoBtn.backgroundColor = [UIColor clearColor];
	UIImage *addVideoImg = [self imageInBundle:@"media_album_video"];
	[self.albumVideoBtn setImage:addVideoImg forState:UIControlStateNormal];
	
	self.durationDotImgView.backgroundColor = [UIColor clearColor];
	UIImage *durationDodImg = [self imageInBundle:@"media_capture_reddot"];
	self.durationDotImgView.image = durationDodImg;
	
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
	
	[self initializeCaptureState];
}

- (void)setCaptureModel:(LZCameraCaptureModel)captureModel {
    _captureModel = captureModel;
    
    switch (captureModel) {
        case LZCameraCaptureModeStillImage: {
			
			self.albumVideoBtn.hidden = YES;
            self.stillImageSingleTap.enabled = YES;
            self.longTap.enabled = NO;
			self.videoSingleTap.enabled = NO;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelShortVideo: {
            
            self.stillImageSingleTap.enabled = NO;
			if (self.maxDuration <= 15) {
				
				self.longTap.enabled = YES;
				self.videoSingleTap.enabled = NO;
			} else {
				
				self.longTap.enabled = NO;
				self.videoSingleTap.enabled = YES;
			}
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelStillImageAndShortVideo: {
			
			self.albumVideoBtn.hidden = YES;
            self.stillImageSingleTap.enabled = YES;
            self.longTap.enabled = YES;
			self.videoSingleTap.enabled = NO;
            self.captureContainerView.hidden = NO;
            self.captureLongVideoContainerView.hidden = YES;
        }
            break;
        case LZCameraCaptureModelLongVideo: {
			
			self.albumVideoBtn.hidden = YES;
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
	
	NSString *timeString = [NSString stringWithFormat:@"%.1f秒", curSeconds];
	self.durationLabel.text = timeString;
}

// MARK: - UI Action
- (IBAction)albumVideoDidClick:(id)sender {
	if (self.TapToAlbumVideoCallback) {
		self.TapToAlbumVideoCallback();
	}
}

- (IBAction)captureLongVideoDidTouch:(UIButton *)sender {
	
    BOOL selected = self.captureLongVideoBtn.selected;
    __weak typeof(self) weakSelf = self;
    if (self.TapToCaptureVideoCallback) {
        self.TapToCaptureVideoCallback(!selected, selected, ^{
			
			typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.captureLongVideoBtn.selected = NO;
			strongSelf.captureLongVideoBtn.userInteractionEnabled = YES;
        });
    }
    self.captureLongVideoBtn.selected = !self.captureLongVideoBtn.selected;
	self.captureLongVideoBtn.userInteractionEnabled = !self.captureLongVideoBtn.selected ? NO : YES;
}

- (void)captureStillImageDidTap:(UITapGestureRecognizer *)gestureRecognizer {
    
    if (self.TapToCaptureImageCallback) {
		
        self.captureContainerView.userInteractionEnabled = NO;
        self.captureImgView.transform = CGAffineTransformMakeScale(0.8, 0.8);
		__weak typeof(self) weakSelf = self;
        self.TapToCaptureImageCallback(^{
			
			typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.captureContainerView.userInteractionEnabled = YES;
            strongSelf.captureImgView.transform = CGAffineTransformIdentity;
        });
    }
}

- (void)captureVideoDidLongTap:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	self.captureImgView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
	UIGestureRecognizerState state = gestureRecognizer.state;
	BOOL begin = state == UIGestureRecognizerStateBegan;
	BOOL end = state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateFailed || state == UIGestureRecognizerStateCancelled;
	self.captureContainerView.userInteractionEnabled = end ? NO : YES;
	[self captureVideo:begin stop:end];
}

- (void)captureVideoDidSingleTap:(UITapGestureRecognizer *)gestureRecognizer {
	
	self.albumVideoBtn.hidden = YES;
	if (NO == self.isRecording) {
		
		self.recording = YES;
		[self captureVideo:YES stop:NO];
	} else {
		
		self.recording = NO;
		[self captureVideo:NO stop:YES];
		self.albumVideoBtn.hidden = NO;
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

 @param start 是否开始
 @param stop 是否停止
 */
- (void)captureVideo:(BOOL)start stop:(BOOL)stop {
	
	if (start) {
		
		self.durationContainerView.hidden = NO;
		self.captureImgView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
	} else {
		self.captureContainerView.userInteractionEnabled = NO;
	}
	
	__weak typeof(self) weakSelf = self;
	self.TapToCaptureVideoCallback(start, stop, ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf initializeCaptureState];
	});
}

/**
 初始化捕捉状态
 */
- (void)initializeCaptureState {
	
	[self.captureContainerProgressView clearProgress];
	self.durationContainerView.hidden = YES;
	self.durationLabel.text = @"0.0秒";
	self.captureImgView.transform = CGAffineTransformIdentity;
	self.captureContainerView.userInteractionEnabled = YES;
}

@end
