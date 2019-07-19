//
//  LZCameraMediaViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import "LZCameraMediaViewController.h"
#import "LZCameraMediaPreviewView.h"
#import "LZCameraMediaStatusView.h"
#import "LZCameraMediaModelView.h"
#import "LZCameraCore.h"
#import "LZCameraMediaPreviewViewController.h"
#if 0
#import <GPUImage/GPUImage.h>
#endif

@interface LZCameraMediaViewController ()<LZCameraControllerDelegate>
#if 0
{
	///GPUImage
	GPUImageMovie *movieFile;
	GPUImageOutput<GPUImageInput> *filter;
	GPUImageMovieWriter *movieWriter;
	CADisplayLink* dlink;
	
	///AVFoundation
	AVAsset * videoAsset;
	AVAssetExportSession *exporter;
}
#endif

@property (weak, nonatomic) IBOutlet LZCameraMediaPreviewView *mediaPreviewView;
@property (weak, nonatomic) IBOutlet LZCameraMediaStatusView *mediaStatusView;
@property (weak, nonatomic) IBOutlet LZCameraMediaModelView *mediaModelView;
@property (weak, nonatomic) IBOutlet UILabel *captureTipLabel;

@property (strong, nonatomic) LZCameraController *cameraController;
@property (strong, nonatomic) UIImage *previewImage;
@property (strong, nonatomic) NSURL *videoURL;
@property (assign, nonatomic) CMTime videoDuration;

@end

@implementation LZCameraMediaViewController

// MARK: - Initialization
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        self.showStatusBar = YES;
        self.showFlashModeInStatusBar = YES;
        self.showSwitchCameraInStatusBar = YES;
        self.captureModel = LZCameraCaptureModelStillImageAndShortVideo;
        self.maxShortVideoDuration = 10.0f;
        self.minVideoDuration = 3.0f;
        self.detectFaces = NO;
		self.autoSaveToAlbum = YES;
        self.videoDuration = kCMTimeZero;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configCameraController];
    [self setupView];
    [self configCaptureTipView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self.cameraController grantCameraAuthority]) {
        
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"请在iPhone的“设置-隐私”选项中，允许%@访问您的摄像头和麦克风。", appName];
        [self alertMessage:message handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

- (void)dealloc {
    [self.cameraController stopSession];
    LZCameraLog();
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"LZCameraPreviewIdentifier"]) {
        
        LZCameraMediaPreviewViewController *ctr = segue.destinationViewController;
        ctr.previewImage = self.previewImage;
        ctr.videoURL = self.videoURL;
		ctr.autoSaveToAlbum = self.autoSaveToAlbum;
        __weak typeof(self) weakSelf = self;
        ctr.TapToSureHandler = ^{
            
            typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.videoURL) {
                if (strongSelf.CameraVideoCompletionHandler) {
                    strongSelf.CameraVideoCompletionHandler(strongSelf.previewImage, strongSelf.videoURL);
                }
            } else {
                if (strongSelf.CameraImageCompletionHandler) {
                    strongSelf.CameraImageCompletionHandler(strongSelf.previewImage);
                }
            }
        };
    }
}

// MARK: - Public
+ (instancetype)instance {
    
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraMediaViewController"
                                                         bundle:bundle];
    return storyboard.instantiateInitialViewController;
}

// MARK: - Private
/**
 配置摄像头
 */
- (void)configCameraController {
	
    LZCameraConfig *cameraConfig = [[LZCameraConfig alloc] init];
	cameraConfig.stillImageAutoWriteToAlbum = self.autoSaveToAlbum;
	cameraConfig.videoAutoWriteToAlbum = self.autoSaveToAlbum;
    cameraConfig.minVideoRecordedDuration = CMTimeMake(self.minVideoDuration, 1);
    if (self.captureModel == LZCameraCaptureModelShortVideo || self.captureModel == LZCameraCaptureModelStillImageAndShortVideo) {
        cameraConfig.maxVideoRecordedDuration = CMTimeMake(self.maxShortVideoDuration, 1);
    }
	cameraConfig.minVideoFreeDiskSpaceLimit = 1500000000;
    self.cameraController = [LZCameraController cameraControllerWithConfig:cameraConfig];
    self.cameraController.delegate = self;
    NSError *error;
    if ([self.cameraController setupSession:&error]) {
        
        self.cameraController.flashMode = AVCaptureFlashModeAuto;
        self.cameraController.torchMode = AVCaptureTorchModeAuto;
        [self.mediaPreviewView setCaptureSesstion:self.cameraController.captureSession];
        [self.cameraController startSession];
    } else {
        LZCameraLog(@"CameraController config error: %@", [error localizedDescription]);
    }
	__weak typeof(self) weakSelf = self;
    [self.cameraController videoRecordedDurationWithProgress:^(CMTime duration) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.videoDuration = duration;
        [strongSelf.mediaStatusView updateDurationTime:duration];
        if (strongSelf.captureModel != LZCameraCaptureModelLongVideo) {
            [strongSelf.mediaModelView updateDurationTime:duration];
        }
    }];
    
    if (self.detectFaces) {
        
        [self.cameraController captureMetaDataObjectWithTypes:@[AVMetadataObjectTypeFace] completionHandler:^(NSArray<AVMetadataObject *> * _Nullable metadataObjects, NSError * _Nullable error) {
            
            typeof(weakSelf) strongSelf = weakSelf;
            NSMutableArray *faces = [NSMutableArray array];
            for (AVMetadataMachineReadableCodeObject *objct in metadataObjects) {
                
                if ([objct isKindOfClass:[AVMetadataFaceObject class]]) {
                    
                    AVMetadataFaceObject *face = (AVMetadataFaceObject *)objct;
                    LZCameraLog(@"Face detected with ID: %li", (long)face.faceID);
                    LZCameraLog(@"Face bounds: %@", NSStringFromCGRect(face.bounds));
                    [faces addObject:face];
                }
            }
            
            [strongSelf.mediaPreviewView detectFaces:faces];
        }];
    }
}

/**
 设置视图
 */
- (void)setupView {
    
    __weak typeof(self) weakSelf = self;
    
    // 预览视图
    self.mediaPreviewView.singleTapToFocusEnable = self.cameraController.cameraSupportTapToFocus;
    self.mediaPreviewView.doubleTapToExposeEnable = self.cameraController.cameraSupportTapToExpose;
    self.mediaPreviewView.TapToFocusAtPointHandler = ^(CGPoint point) {
        [weakSelf.cameraController focusAtPoint:point];
    };
    self.mediaPreviewView.TapToExposeAtPointHandler = ^(CGPoint point) {
        [weakSelf.cameraController exposeAtPoint:point];
    };
    self.mediaPreviewView.TapToResetFocusAndExposure = ^{
        [weakSelf.cameraController resetFocusAndExposureMode];
    };
    self.mediaPreviewView.PinchToZoomHandler = ^(BOOL complete, BOOL magnify, CGFloat rampZoomValue) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        if (magnify) {
             [strongSelf.cameraController rampZoomValue:1.0f];
        } else {
            [strongSelf.cameraController rampZoomValue:0.0f];
        }
        if (complete) {
            [strongSelf.cameraController cancelRampingZoom];
        }
    };

    // 状态视图
    self.mediaStatusView.hidden = !self.showStatusBar;
    [self controlFlashModelVisulState];
    [self controlSwitchCameraVisualState];
    self.mediaStatusView.captureModel = self.captureModel;
	self.mediaStatusView.TapToCloseCaptureHandler = ^{
		[weakSelf dismissViewControllerAnimated:YES completion:nil];
	};
    self.mediaStatusView.TapToFlashModelHandler = ^(NSUInteger model) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.cameraController.flashMode = model;
        strongSelf.cameraController.torchMode = model;
    };
    self.mediaStatusView.TapToSwitchCameraHandler = ^{
        
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.cameraController switchCameras];
        [strongSelf controlFlashModelVisulState];
    };
    
    // 拍摄视图
	self.mediaModelView.maxDuration = self.maxShortVideoDuration;
    self.mediaModelView.captureModel = self.captureModel;
    self.mediaModelView.TapToCaptureImageHandler = ^(void (^ _Nonnull ComplteHandler)(void)) {
        
        lzPlaySound(@"media_capture_image.wav", @"LZCameraMedia");
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.cameraController captureStillImage:^(UIImage * _Nonnull stillImage, NSError * _Nullable error) {
            
            if (stillImage) {
                
                strongSelf.previewImage = stillImage;
                strongSelf.videoURL = nil;
                [strongSelf performSegueWithIdentifier:@"LZCameraPreviewIdentifier" sender:stillImage];
            }
            ComplteHandler();
        }];
    };
	
    self.mediaModelView.TapToCaptureVideoHandler = ^(BOOL began, BOOL end, void (^ _Nonnull ComplteHandler)(void)) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        if (began) {
			
			if (NO == strongSelf.captureTipLabel.hidden) {
				[strongSelf hideCaptureTip];
			}
            [strongSelf.mediaStatusView updateFlashVisualState:LZControlVisualStateOff];
            [strongSelf.mediaStatusView updateSwitchCameraVisualState:LZControlVisualStateOff];
            [strongSelf.cameraController startVideoRecording:^(NSURL * _Nonnull videoURL, UIImage * _Nullable thumbnail, NSError * _Nullable error) {
				
				LZCameraLog(@"录制视频完成:%@", error);
                [strongSelf controlFlashModelVisulState];
                [strongSelf controlSwitchCameraVisualState];
                [strongSelf.mediaStatusView updateDurationTime:kCMTimeZero];
				
                if (error) {
                    [strongSelf alertMessage:error.localizedDescription handler:nil];
                } else {
                   
                    CMTime minTime = CMTimeMake(strongSelf.minVideoDuration, 1);
                    int32_t compareResult = CMTimeCompare(strongSelf.videoDuration, minTime);
                    if (compareResult >= 0) {
                        
                        strongSelf.previewImage = thumbnail;
                        strongSelf.videoURL = videoURL;
						[strongSelf performSegueWithIdentifier:@"LZCameraPreviewIdentifier" sender:videoURL];
                    } else {
						
                        [strongSelf showCaputreTip:@"视频时间太短"];
						[strongSelf deleteVideo:videoURL];
                    }
                }
				ComplteHandler();
            }];
        } else if (end) {
            [strongSelf.cameraController stopVideoRecording];
        }
    };
}

/**
 删除视频文件
 
 @param videoURL NSURL
 */
- (void)deleteVideo:(NSURL *)videoURL {
	
	NSError *error;
	NSFileManager *fileM = [NSFileManager defaultManager];
	[fileM removeItemAtURL:videoURL error:&error];
	if (error) {
		LZCameraLog(@"删除视频文件失败:%@", error);
	}
}

#if 0
/**
 使用GPUImage加载水印
 
 @param vedioPath 视频路径
 @param img 水印图片
 @param coverImg 水印图片二
 @param question 字符串水印
 @param fileName 生成之后的视频名字
 */
-(void)saveVedioPath:(NSURL*)vedioPath WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question WithFileName:(NSString*)fileName WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler {
	// 滤镜
	//    filter = [[GPUImageDissolveBlendFilter alloc] init];
	//    [(GPUImageDissolveBlendFilter *)filter setMix:0.0f];
	//也可以使用透明滤镜
	//    filter = [[GPUImageAlphaBlendFilter alloc] init];
	//    //mix即为叠加后的透明度,这里就直接写1.0了
	//    [(GPUImageDissolveBlendFilter *)filter setMix:1.0f];
	
	filter = [[GPUImageNormalBlendFilter alloc] init];
	
	NSURL *sampleURL  = vedioPath;
	AVAsset *asset = [AVAsset assetWithURL:sampleURL];
	CGSize size = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize];
	
	movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
	movieFile.playAtActualSpeed = NO;
	
	// 文字水印
	UILabel *label = [[UILabel alloc] init];
	label.text = question;
	label.font = [UIFont systemFontOfSize:30];
	label.textColor = [UIColor whiteColor];
	[label setTextAlignment:NSTextAlignmentCenter];
	[label sizeToFit];
	label.layer.masksToBounds = YES;
	label.layer.cornerRadius = 18.0f;
	[label setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
	[label setFrame:CGRectMake(50, 100, label.frame.size.width+20, label.frame.size.height)];
	
	//图片水印
	UIImage *coverImage1 = [img copy];
	UIImageView *coverImageView1 = [[UIImageView alloc] initWithImage:coverImage1];
	[coverImageView1 setFrame:CGRectMake(0, 100, 210, 50)];
	
//	//第二个图片水印
//	UIImage *coverImage2 = [coverImg copy];
//	UIImageView *coverImageView2 = [[UIImageView alloc] initWithImage:coverImage2];
//	[coverImageView2 setFrame:CGRectMake(270, 100, 210, 50)];
	
	UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	subView.backgroundColor = [UIColor clearColor];
	
	[subView addSubview:coverImageView1];
//	[subView addSubview:coverImageView2];
	[subView addSubview:label];
	
	
	GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:subView];
	NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.mp4",fileName]];
	unlink([pathToMovie UTF8String]);
	NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
	
	movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
	
	GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
	[progressFilter addTarget:filter];
	[movieFile addTarget:progressFilter];
	[uielement addTarget:filter];
	movieWriter.shouldPassthroughAudio = YES;
	if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0){
		movieFile.audioEncodingTarget = movieWriter;
	} else {//no audio
		movieFile.audioEncodingTarget = nil;
	}
	//    movieFile.playAtActualSpeed = true;
	[movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
	// 显示到界面
	[filter addTarget:movieWriter];
	
	[movieWriter startRecording];
	[movieFile startProcessing];
	
	//    dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
	//    [dlink setFrameInterval:15];
	//    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	//    [dlink setPaused:NO];
	
	__weak typeof(self) weakSelf = self;
	//渲染
	[progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
		//水印可以移动
//		CGRect frame = coverImageView1.frame;
//		frame.origin.x += 1;
//		frame.origin.y += 1;
//		coverImageView1.frame = frame;
		//第5秒之后隐藏coverImageView2
//		if (time.value/time.timescale>=5.0) {
//			[coverImageView2 removeFromSuperview];
//		}
//		[uielement update];
		
	}];
	//保存相册
	[movieWriter setCompletionBlock:^{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			__strong typeof(self) strongSelf = weakSelf;
			[strongSelf->filter removeTarget:strongSelf->movieWriter];
			[strongSelf->movieWriter finishRecording];
			
			if (handler) {
				handler(movieURL, 0);
			}
		});
	}];
}

- (void)addWaterMarkTypeWithCorAnimationAndInputVideoURL:(NSURL*)InputURL WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler{
	
	NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
	AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:InputURL options:opts];
	AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
	AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
																		preferredTrackID:kCMPersistentTrackID_Invalid];
	NSError *errorVideo = [NSError new];
	AVAssetTrack *assetVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo]firstObject];
	CMTime endTime = assetVideoTrack.asset.duration;
	BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetVideoTrack.asset.duration)
								  ofTrack:assetVideoTrack
								   atTime:kCMTimeZero error:&errorVideo];
	videoTrack.preferredTransform = assetVideoTrack.preferredTransform;
	NSLog(@"errorVideo:%ld%d",errorVideo.code,bl);
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyyMMddHHmmss";
	NSString *outPutFileName = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
	NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",outPutFileName]];
	NSURL* outPutVideoUrl = [NSURL fileURLWithPath:myPathDocs];
	
	CGSize videoSize = [videoTrack naturalSize];
	
	UIFont *font = [UIFont systemFontOfSize:60.0];
	CATextLayer *aLayer = [[CATextLayer alloc] init];
	[aLayer setFontSize:60];
	[aLayer setString:@"H"];
	[aLayer setAlignmentMode:kCAAlignmentCenter];
	[aLayer setForegroundColor:[[UIColor greenColor] CGColor]];
	[aLayer setBackgroundColor:[UIColor clearColor].CGColor];
	CGSize textSize = [@"H" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
	[aLayer setFrame:CGRectMake(240, 470, textSize.width, textSize.height)];
	aLayer.anchorPoint = CGPointMake(0.5, 1.0);
	
	
	CATextLayer *bLayer = [[CATextLayer alloc] init];
	[bLayer setFontSize:60];
	[bLayer setString:@"E"];
	[bLayer setAlignmentMode:kCAAlignmentCenter];
	[bLayer setForegroundColor:[[UIColor greenColor] CGColor]];
	[bLayer setBackgroundColor:[UIColor clearColor].CGColor];
	CGSize textSizeb = [@"E" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
	[bLayer setFrame:CGRectMake(240 + textSize.width, 470 , textSizeb.width, textSizeb.height)];
	bLayer.anchorPoint = CGPointMake(0.5, 1.0);
	
	
	CATextLayer *cLayer = [[CATextLayer alloc] init];
	[cLayer setFontSize:60];
	[cLayer setString:@"L"];
	[cLayer setAlignmentMode:kCAAlignmentCenter];
	[cLayer setForegroundColor:[[UIColor greenColor] CGColor]];
	[cLayer setBackgroundColor:[UIColor clearColor].CGColor];
	CGSize textSizec = [@"L" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
	[cLayer setFrame:CGRectMake(240 + textSizeb.width + textSize.width, 470 , textSizec.width, textSizec.height)];
	cLayer.anchorPoint = CGPointMake(0.5, 1.0);
	
	
	CATextLayer *dLayer = [[CATextLayer alloc] init];
	[dLayer setFontSize:60];
	[dLayer setString:@"L"];
	[dLayer setAlignmentMode:kCAAlignmentCenter];
	[dLayer setForegroundColor:[[UIColor greenColor] CGColor]];
	[dLayer setBackgroundColor:[UIColor clearColor].CGColor];
	CGSize textSized = [@"L" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
	[dLayer setFrame:CGRectMake(240 + textSizec.width+ textSizeb.width + textSize.width, 470 , textSized.width, textSized.height)];
	dLayer.anchorPoint = CGPointMake(0.5, 1.0);
	
	CATextLayer *eLayer = [[CATextLayer alloc] init];
	[eLayer setFontSize:60];
	[eLayer setString:@"O"];
	[eLayer setAlignmentMode:kCAAlignmentCenter];
	[eLayer setForegroundColor:[[UIColor greenColor] CGColor]];
	[eLayer setBackgroundColor:[UIColor clearColor].CGColor];
	CGSize textSizede = [@"O" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
	[eLayer setFrame:CGRectMake(240 + textSized.width + textSizec.width+ textSizeb.width + textSize.width, 470 , textSizede.width, textSizede.height)];
	eLayer.anchorPoint = CGPointMake(0.5, 1.0);
	
	CABasicAnimation* basicAni = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	basicAni.fromValue = @(0.2f);
	basicAni.toValue = @(1.0f);
	basicAni.beginTime = AVCoreAnimationBeginTimeAtZero;
	basicAni.duration = 2.0f;
	basicAni.repeatCount = HUGE_VALF;
	basicAni.removedOnCompletion = NO;
	basicAni.fillMode = kCAFillModeForwards;
	[aLayer addAnimation:basicAni forKey:nil];
	[bLayer addAnimation:basicAni forKey:nil];
	[cLayer addAnimation:basicAni forKey:nil];
	[dLayer addAnimation:basicAni forKey:nil];
	[eLayer addAnimation:basicAni forKey:nil];
	
	CALayer *parentLayer = [CALayer layer];
	CALayer *videoLayer = [CALayer layer];
	parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
	videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
	[parentLayer addSublayer:videoLayer];
	[parentLayer addSublayer:aLayer];
	[parentLayer addSublayer:bLayer];
	[parentLayer addSublayer:cLayer];
	[parentLayer addSublayer:dLayer];
	[parentLayer addSublayer:eLayer];
	
	AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
	videoComp.renderSize = videoSize;
	parentLayer.geometryFlipped = true;
	videoComp.frameDuration = CMTimeMake(1, 30);
	videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
	AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	
	instruction.timeRange = CMTimeRangeMake(kCMTimeZero, endTime);
	AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];
	videoComp.instructions = [NSArray arrayWithObject: instruction];
	
	
	AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
																	  presetName:AVAssetExportPresetHighestQuality];
	exporter.outputURL=outPutVideoUrl;
	exporter.outputFileType = AVFileTypeMPEG4;
	exporter.shouldOptimizeForNetworkUse = YES;
	exporter.videoComposition = videoComp;
	[exporter exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			//这里是输出视频之后的操作，做你想做的
			NSLog(@"输出视频地址:%@ andCode:%@",myPathDocs,exporter.error);
			handler(outPutVideoUrl,(int)exporter.error.code);
		});
	}];
}
#endif

/**
 控制闪光灯可视状态
 */
- (void)controlFlashModelVisulState {
    
    LZControlVisualState state = LZControlVisualStateOff;
    if (self.showFlashModeInStatusBar) {
        
        if ([self.cameraController cameraHasFlash] || [self.cameraController cameraHasTorch]) {
            state = LZControlVisualStateOn;
        }
    }
    [self.mediaStatusView updateFlashVisualState:state];
}

/**
 控制切换摄像头可视状态
 */
- (void)controlSwitchCameraVisualState {
    
    LZControlVisualState state = LZControlVisualStateOff;
    if (self.showSwitchCameraInStatusBar) {
        
        if ([self.cameraController canSwitchCameras]) {
            state = LZControlVisualStateOn;
        }
    }
    [self.mediaStatusView updateSwitchCameraVisualState:state];
}

/**
 配置捕捉提示
 */
- (void)configCaptureTipView {
    
    NSString *tipString = nil;
    switch (self.captureModel) {
        case LZCameraCaptureModeStillImage:
            tipString = @"轻触拍照";
            break;
        case LZCameraCaptureModelShortVideo:
			if (self.maxShortVideoDuration < 15) {
				tipString = @"按住录像";
			} else {
				tipString = @"轻触录像，再次轻触停止";
			}
            break;
        case LZCameraCaptureModelStillImageAndShortVideo:
            tipString = @"轻触拍照，按住录像";
            break;
        case LZCameraCaptureModelLongVideo:
            tipString = nil;
            break;
        default:
            break;
    }
    [self showCaputreTip:tipString];
}

/**
 展示捕捉提示

 @param tipMessage NSString
 */
- (void)showCaputreTip:(NSString *)tipMessage {
    
    if (!tipMessage || tipMessage.length == 0) {
		[self hideCaptureTip];
        return;
    }
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 10.0f;
    shadow.shadowOffset = CGSizeMake(0, 0);
    shadow.shadowColor = [UIColor blackColor];
    NSDictionary *attributes = @{NSShadowAttributeName : shadow};
    NSMutableAttributedString *attributedString =
    [[NSMutableAttributedString alloc] initWithString:tipMessage attributes:attributes];
    self.captureTipLabel.hidden = NO;
    self.captureTipLabel.attributedText = attributedString;
    [self performSelector:@selector(hideCaptureTip) withObject:nil afterDelay:2.0f];
}

/**
 隐藏捕捉提示
 */
- (void)hideCaptureTip {
    self.captureTipLabel.hidden = YES;
}

/**
 提示错误

 @param message NSString
 */
- (void)alertMessage:(NSString *)message handler:(void (^)(UIAlertAction *action))handler {
    
    UIAlertController *alertCtr =
    [UIAlertController alertControllerWithTitle:@"提示"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定"
                                                 style:UIAlertActionStyleDefault
                                               handler:handler]];
    [self presentViewController:alertCtr animated:YES completion:nil];
}

// MARK: - Delegate
// MARK: <LZCameraControllerDelegate>
- (void)cameraConfigurationFailWithError:(NSError *)error {
    [self alertMessage:error.localizedDescription handler:nil];
}

- (void)photosAlbumWriteFailedWithError:(NSError *)error {
    [self alertMessage:error.localizedDescription handler:nil];
}

@end
