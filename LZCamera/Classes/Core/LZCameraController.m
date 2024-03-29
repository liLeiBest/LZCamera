//
//  LZCameraController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/15.
//

#import "LZCameraController.h"
#import "LZCameraToolkit.h"

#define LZMainQueue dispatch_get_main_queue()
#define LZMainQueueBlock(block) { \
    if ([NSThread isMainThread]) { \
        void(^exBlock)(void) = block; \
        exBlock(); \
    } else { \
            dispatch_async(LZMainQueue, block); \
    } \
}
#define LZCameraQueueBlock(block) \
dispatch_async(cameraQueue, block);

/** 用于监听视频缩放因子的键 */
static NSString * const LZCameraVideoZoomFactorKey = @"videoZoomFactor";
/** 用于监听视频缩放因子的上下文 */
static const NSString * LZCameraVideoZoomFactorContext;
/** 用于监听视频阶梯缩放的键 */
static NSString * const LZCameraVideoRampingZoomKey = @"rampingVideoZoom";
/** 用于监听视频阶梯缩放的上下文 */
static const NSString * LZCameraVideoRampingZoomContext;
/** 用于监听摄像头正在曝光的键 */
static NSString * const LZCameraAdjustingExposureKey = @"adjustingExposure";
/** 用于监听摄像头正在曝光的上下文 */
static const NSString * LZCameraAdjustingExposureContext;

@interface LZCameraController()<AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>{
    dispatch_queue_t cameraQueue;
}

/** 配置信息 */
@property (strong, nonatomic) LZCameraConfig *cameraConfig;
/** 捕捉会话 */
@property (strong, nonatomic) AVCaptureSession *captureSession;
/** 当前的可用的摄像头 */
@property (weak, nonatomic) AVCaptureDeviceInput *activeMediaInput;

/** 输出元数据*/
@property (strong, nonatomic) AVCaptureMetadataOutput *metadataOutput;
/** 输出为静态图片 */
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
/** 输出为视频文件 */
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
/** 视频文件路径 */
@property (strong, nonatomic) NSURL *videoFileOutputURL;

/** 保存捕捉图片完成回调 */
@property (copy, nonatomic) LZCameraCaptureStillImageCompletionHandler captureStillImageCompletionHandler;
/** 保存捕捉视频完成回调 */
@property (copy, nonatomic) LZCameraCaptureVideoCompletionHandler captureVideoCompletionHandler;
/** dispatch_source_t */
@property (nonatomic) dispatch_source_t gcdSource;

@end

@implementation LZCameraController

// MARK: - Initialization
- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        cameraQueue = dispatch_queue_create("com.lzcamera.captureVideo", DISPATCH_QUEUE_SERIAL);
        self.cameraConfig = [[LZCameraConfig alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - Public
+ (instancetype)cameraController {
    return [[self alloc] init];
}

+ (instancetype)cameraControllerWithConfig:(LZCameraConfig *)config {
    
    LZCameraController *cameraController = [self cameraController];
    cameraController.cameraConfig = config;
    return cameraController;
}

- (BOOL)setupSession:(NSError **)error {
    
    self.captureSession = [[AVCaptureSession alloc] init];
    AVCaptureSessionPreset sessionPreset = [self sessionPreset];
    if ([self.captureSession canSetSessionPreset:sessionPreset]) {
        self.captureSession.sessionPreset = sessionPreset;
    }
    
    if (![self setupSessionInputs:error]) {
        LZCameraLog(@"%@", *error);
        return NO;
    }
    
    if (![self setupSessionOutputs:error]) {
        LZCameraLog(@"%@", *error);
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(interruptedStart:)
     name:AVCaptureSessionWasInterruptedNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(interruptedEnd:)
     name:AVCaptureSessionInterruptionEndedNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(runStart:)
     name:AVCaptureSessionDidStartRunningNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(runStop:)
     name:AVCaptureSessionDidStopRunningNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(runError:)
     name:AVCaptureSessionRuntimeErrorNotification
     object:nil];
    
    return YES;
}

- (void)startSession {
    
    LZCameraQueueBlock(^{
        if (![self.captureSession isRunning]) {
            [self.captureSession startRunning];
        }
    })
}

- (void)stopSession {
    
    LZMainQueueBlock(^{
        if ([self.captureSession isRunning]) {
            [self.captureSession stopRunning];
        }
    })
}

- (AVCaptureSessionPreset)sessionPreset {
    return AVCaptureSessionPresetHigh;
}

- (BOOL)setupSessionInputs:(NSError **)error {
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    if (NO == [self updateSessionVideoInput:videoDeviceInput]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add audio input."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddInput
                                 userInfo:userInfo];
        return NO;
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
    if (audioDeviceInput) {
        if ([self.captureSession canAddInput:audioDeviceInput]) {
            [self.captureSession addInput:audioDeviceInput];
        } else {
            
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add audio input."};
            *error = [NSError errorWithDomain:LZCameraErrorDomain
                                         code:LZCameraErrorFailedToAddInput
                                     userInfo:userInfo];
        }
    } else {
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add audio input."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddInput
                                 userInfo:userInfo];
        return NO;
    }
    return YES;
}

- (BOOL)updateSessionVideoInput:(AVCaptureDeviceInput *)videoInput {
    
    BOOL flag = YES;
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.activeMediaInput];
    if ([self.captureSession canAddInput:videoInput]) {
        
        [self.captureSession addInput:videoInput];
        self.activeMediaInput = videoInput;
    } else if ([self.captureSession canAddInput:self.activeMediaInput]) {
        
        [self.captureSession addInput:self.activeMediaInput];
    } else {
        flag = NO;
    }
    [self.captureSession commitConfiguration];
    [self regiesterObserverForVideoZoom];
    return flag;
}

- (BOOL)setupSessionOutputs:(NSError **)error {
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    AVVideoCodecType videoCodecType;
    if (@available(ios 11, *)) {
        videoCodecType = AVVideoCodecTypeJPEG;
    } else {
        videoCodecType = AVVideoCodecJPEG;
    }
    self.stillImageOutput.outputSettings = @{AVVideoCodecKey : videoCodecType};
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    } else {
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to still image output."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddOutput
                                 userInfo:userInfo];
        return NO;
    }
    
    self.videoFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    self.videoFileOutput.maxRecordedDuration = self.cameraConfig.maxVideoRecordedDuration;
    self.videoFileOutput.maxRecordedFileSize = self.cameraConfig.maxVideoRecordedFileSize;
    self.videoFileOutput.minFreeDiskSpaceLimit = self.cameraConfig.minVideoFreeDiskSpaceLimit;
    AVCaptureConnection *connection = [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoStabilizationSupported) {
        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    }
    if ([self.captureSession canAddOutput:self.videoFileOutput]) {
        [self.captureSession addOutput:self.videoFileOutput];
    } else {
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to video output."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddOutput
                                 userInfo:userInfo];
        return NO;
    }
    
    if (self.cameraConfig.metaObjectTypes && self.cameraConfig.metaObjectTypes.count) {
        if (![self configMetaDataOutputWith:self.cameraConfig.metaObjectTypes error:error]) {
            return NO;
        }
    }
    
    return YES;
}

- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (BOOL)canSwitchCameras {
    return self.cameraCount > 1;
}

- (BOOL)switchCameras {
    
    if (![self canSwitchCameras] || [self isVideoRecording]) {
        return NO;
    }
    
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamera];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (videoDeviceInput) {
        
        [self removeObserverForVideoZoom];
        CGFloat zoomValue = [self currentVideoZoomValue];
        [self updateSessionVideoInput:videoDeviceInput];
        [self setZoomValue:zoomValue];
        if (self.captureMetaDataCompletionHandler) {
            self.captureMetaDataCompletionHandler(nil, nil);
        }
    } else {
        
        [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                      withObject:error];
        return NO;
    }
    
    return YES;
}

- (BOOL)cameraHasTorch {
    return [[self activeCamera] hasTorch];
}

- (BOOL)cameraHasFlash {
    return [[self activeCamera] hasFlash];
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
 
    AVCaptureDevice *camera = [self activeCamera];
    if (camera.torchMode != torchMode && [camera isTorchModeSupported:torchMode]) {
        
        NSError *error;
        if ([camera lockForConfiguration:&error]) {
            
            camera.torchMode = torchMode;
            [camera unlockForConfiguration];
        } else {
            [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                          withObject:error];
        }
    }
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    
    AVCaptureDevice *camera = [self activeCamera];
    if (camera.flashMode != flashMode && [camera isFlashModeSupported:flashMode]) {
        
        NSError *error;
        if ([camera lockForConfiguration:&error]) {
            
            camera.flashMode = flashMode;
            [camera unlockForConfiguration];
        } else {
            [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                          withObject:error];
        }
    }
}

- (BOOL)cameraSupportTapToFocus {
    return [[self activeCamera] isFocusPointOfInterestSupported];
}

- (BOOL)cameraSupportTapToExpose {
    return [[self activeCamera] isExposurePointOfInterestSupported];
}

- (BOOL)cameraSupportZoom {
    return [self activeCamera].activeFormat.videoMaxZoomFactor > 1.0f;
}

- (void)focusAtPoint:(CGPoint)point {
    
    AVCaptureDevice *camera = [self activeCamera];
    if (camera.isFocusPointOfInterestSupported && [camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        if ([camera lockForConfiguration:&error]) {
            
            camera.focusPointOfInterest = point;
            camera.focusMode = AVCaptureFocusModeAutoFocus;
            [camera unlockForConfiguration];
        } else {
            [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                          withObject:error];
        }
    }
}

- (void)exposeAtPoint:(CGPoint)point {
    
    AVCaptureDevice *camera = [self activeCamera];
    AVCaptureExposureMode exposureModel = AVCaptureExposureModeContinuousAutoExposure;
    if ([camera isExposurePointOfInterestSupported] && [camera isExposureModeSupported:exposureModel]) {
        
        NSError *error;
        if ([camera lockForConfiguration:&error]) {
            
            camera.exposurePointOfInterest = point;
            camera.exposureMode = exposureModel;
            if ([camera isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [camera addObserver:self
                         forKeyPath:LZCameraAdjustingExposureKey
                            options:NSKeyValueObservingOptionNew
                            context:&LZCameraAdjustingExposureContext];
            }
            [camera unlockForConfiguration];
        } else {
            [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                          withObject:error];
        }
    }
}

- (void)resetFocusAndExposureMode {
    
    AVCaptureDevice *camera = [self activeCamera];
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    BOOL canResetFocus = [camera isFocusPointOfInterestSupported] && [camera isFocusModeSupported:focusMode];
    BOOL canResetExposure = [camera isExposurePointOfInterestSupported] && [camera isExposureModeSupported:exposureMode];
    
    NSError *error;
    if ([camera lockForConfiguration:&error]) {
        
        CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
        if (canResetFocus) {
            
            camera.focusMode = focusMode;
            camera.focusPointOfInterest = centerPoint;
        }
        
        if (canResetExposure) {
            
            camera.exposureMode = exposureMode;
            camera.exposurePointOfInterest = centerPoint;
        }
        [camera unlockForConfiguration];
    } else {
        [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                      withObject:error];
    }
}

- (void)setZoomValue:(CGFloat)zoomValue {
    
    AVCaptureDevice *camera = [self activeCamera];
    if (!camera.isRampingVideoZoom) {
        
        NSError *error;
        if ([camera lockForConfiguration:&error]) {
            
            CGFloat zoomFactor = [self calculateMaxZoomFactorWithZoomValue:zoomValue];
            camera.videoZoomFactor = zoomFactor;
            [camera unlockForConfiguration];
        } else {
            [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                          withObject:error];
        }
    }
}

- (void)rampZoomValue:(CGFloat)zoomValue {
    
    AVCaptureDevice *camera = [self activeCamera];
    NSError *error;
    if ([camera lockForConfiguration:&error]) {
        
        CGFloat zoomfactor = [self calculateMaxZoomFactorWithZoomValue:zoomValue];
        [camera rampToVideoZoomFactor:zoomfactor withRate:self.cameraConfig.cameraZoomRate];
        [camera unlockForConfiguration];
    } else {
        [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                      withObject:error];
    }
}

- (void)cancelRampingZoom {
    
    AVCaptureDevice *camera = [self activeCamera];
    NSError *error;
    if ([camera lockForConfiguration:&error]) {
        
        [camera cancelVideoZoomRamp];
        [camera unlockForConfiguration];
    } else {
        [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                      withObject:error];
    }
}

- (void)captureStillImage:(LZCameraCaptureStillImageCompletionHandler)completionHandler {
	
    LZCameraQueueBlock(^{
        
        self.captureStillImageCompletionHandler = completionHandler;
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = [self currentVideoOrientation];
        }
        if (connection.isVideoMirroringSupported) {
            
            AVCaptureDevice *device = [self activeCamera];
            connection.videoMirrored = device.position == AVCaptureDevicePositionFront || device.position == AVCaptureDevicePositionUnspecified;
        }
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection
                                                           completionHandler:
         ^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
             
             if (NULL != imageDataSampleBuffer) {
                 
                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                 UIImage *image = [UIImage imageWithData:imageData];
                 if (!self.cameraConfig.stillImageAutoWriteToAlbum) {
                     [self callBackStillImageOnMainQueue:image error:nil];
                 } else {
                     [self writeImageToPhotosAlbum:image];
                 }
             } else {
                 [self callBackStillImageOnMainQueue:nil error:error];
             }
         }];
    })
}

- (void)startVideoRecording:(LZCameraCaptureVideoCompletionHandler)completionHandler {
	
    LZCameraQueueBlock(^{
        
        if (![self isVideoRecording]) {
            
            self.captureVideoCompletionHandler = completionHandler;
            AVCaptureDevice *device = [self activeCamera];
            AVCaptureConnection *connection = [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoOrientationSupported) {
                connection.videoOrientation = [self currentVideoOrientation];
            }
            if (connection.isVideoMirroringSupported) {
                connection.videoMirrored = device.position == AVCaptureDevicePositionFront || device.position == AVCaptureDevicePositionUnspecified;
            }
            if (device.isSmoothAutoFocusSupported) {
                
                NSError *error;
                if ([device lockForConfiguration:&error]) {
                    
                    device.smoothAutoFocusEnabled = YES;
                    [device unlockForConfiguration];
                } else {
                    LZMainQueueBlock(^{
                        [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                                      withObject:error];
                    })
                }
            }
            
            self.videoFileOutputURL = [LZCameraToolkit generateUniqueAssetFileURL:LZCameraAssetTypeMov];
			LZCameraLog(@"视频输出路径:%@", self.videoFileOutputURL);
            if (self.videoFileOutputURL) {
                [self.videoFileOutput startRecordingToOutputFileURL:self.videoFileOutputURL recordingDelegate:self];
            } else {
                
                NSString *errorDescription = @"Failed to invalide output url";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription};
                NSError *error = [NSError errorWithDomain:LZCameraErrorDomain
                                                     code:LZCameraErrorInvalideFileOutputURL
                                                 userInfo:userInfo];
                LZMainQueueBlock(^{
                    [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                                  withObject:error];
                })
            }
        }
    })
}

- (void)stopVideoRecording {
    
	LZMainQueueBlock(^{
        if ([self isVideoRecording]) {
            [self.videoFileOutput stopRecording];
        }
    })
}

- (BOOL)isVideoRecording {
	return self.videoFileOutput.isRecording;
}

- (CMTime)videoRecordedDuration {
	return self.videoFileOutput.recordedDuration;
}

- (void)videoRecordedDurationWithProgress:(LZCameraRecordedDurationProgressHandler)progressHandler {
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, LZMainQueue);
    self.gcdSource = timer;
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.25f * NSEC_PER_SEC, 0.0f * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        if (progressHandler) {
            
            CMTime duration = [self isVideoRecording] ? [self videoRecordedDuration] : kCMTimeZero;
            progressHandler(duration);
        }
    });
}

- (int64_t)videoRecordedFileSize {
    return self.videoFileOutput.recordedFileSize;
}

- (void)captureMetaDataObjectWithTypes:(NSArray<AVMetadataObjectType> *)metaObjectTypes
                     completionHandler:(LZCameraCaptureMetaDataCompletionHandler)completionHandler {
    
    LZCameraQueueBlock(^{
    
        self.captureMetaDataCompletionHandler = completionHandler;
        [self.captureSession beginConfiguration];
        [self configMetaDataOutputWith:metaObjectTypes error:NULL];
        [self.captureSession commitConfiguration];
    })
}

- (BOOL)grantCameraAuthority {
    
    BOOL grantVideo = YES;
    BOOL grantAudio = YES;
    AVAuthorizationStatus authorizationStatusForVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatusForVideo == AVAuthorizationStatusRestricted || authorizationStatusForVideo == AVAuthorizationStatusDenied) {
        grantVideo = NO;
    }
    
    AVAuthorizationStatus authorizationStatusForAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authorizationStatusForAudio == AVAuthorizationStatusRestricted || authorizationStatusForAudio == AVAuthorizationStatusDenied) {
        grantAudio = NO;
    }
    
    if (grantVideo && grantAudio) {
        return YES;
    }
    
    return NO;
}

// MARK: - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    
    if (context == &LZCameraAdjustingExposureContext) {
        
        AVCaptureDevice *camera = (AVCaptureDevice *)object;
        if (!camera.isAdjustingExposure && [camera isExposureModeSupported:AVCaptureExposureModeLocked]) {
            
            [object removeObserver:self
                        forKeyPath:LZCameraAdjustingExposureKey
                           context:&LZCameraAdjustingExposureContext];
            LZMainQueueBlock(^{
                NSError *error;
                if ([camera lockForConfiguration:&error]) {
                    
                    camera.exposureMode = AVCaptureExposureModeLocked;
                    [camera unlockForConfiguration];
                } else {
                    [self performDelegateSelectorIfSupported:@selector(cameraConfigurationFailWithError:)
                                                  withObject:error];
                }
            })
        }
    } else if (context == &LZCameraVideoZoomFactorContext) {
        [self callBackVideoZoomValueOnMainQueue];
    } else if (context == &LZCameraVideoRampingZoomContext) {
        
        if ([self activeCamera].isRampingVideoZoom) {
            [self callBackVideoZoomValueOnMainQueue];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)interruptedStart:(NSNotificationCenter *)notification {
    LZCameraLog(@"中断开始:%@", notification);
}

- (void)interruptedEnd:(NSNotificationCenter *)notification {
   LZCameraLog(@"中断结束:%@", notification);
}

- (void)runStart:(NSNotificationCenter *)notification {
    LZCameraLog(@"启动会话:%@", notification);
}

- (void)runStop:(NSNotificationCenter *)notification {
    LZCameraLog(@"终止会话:%@", notification);
}

- (void)runError:(NSNotificationCenter *)notification {
    LZCameraLog(@"会话出错:%@", notification);
}

// MARK: - Delegate
// MARK: <AVCaptureFileOutputRecordingDelegate>
- (void)captureOutput:(AVCaptureFileOutput *)output
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
    LZCameraLog(@"Start record video.");
    if (self.gcdSource) {
        dispatch_resume(self.gcdSource);
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)output
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
	  fromConnections:(NSArray<AVCaptureConnection *> *)connections
				error:(NSError *)error {
	
    LZCameraLog(@"Finish record video.");
    if (self.gcdSource) {
        dispatch_suspend(self.gcdSource);
    }
    
	if (error) {
        if ((error.code == AVErrorMaximumFileSizeReached || error.code == AVErrorMaximumDurationReached)) {
            
            NSDictionary *userInfo = error.userInfo;
            NSArray *allKeys = userInfo.allKeys;
            if ([allKeys containsObject:AVErrorRecordingSuccessfullyFinishedKey] ) {
                if ((BOOL)[[userInfo objectForKey:AVErrorRecordingSuccessfullyFinishedKey] boolValue]) {
                    [self captureVideoFileFinish:[self.videoFileOutputURL copy] error:nil];
                }
			} else {
				[LZCameraToolkit deleteFile:self.videoFileOutputURL];
                [LZCameraToolkit deleteFile:self.videoFileOutputURL.URLByDeletingLastPathComponent];
			}
        } else {
            
            CMTime duratedTime = [self videoRecordedDuration];
            if (CMTIME_IS_VALID(duratedTime) && CMTimeCompare(duratedTime, self.cameraConfig.minVideoRecordedDuration) >= 0) {
                [self captureVideoFileFinish:[self.videoFileOutputURL copy] error:nil];
            } else {
                
                if (error.code == AVErrorDiskFull) {
                    
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to disk full."};
                    error = [NSError errorWithDomain:LZCameraErrorDomain
                                                code:LZCameraErrorDiskFull
                                            userInfo:userInfo];
                } else if (error.code == AVErrorSessionWasInterrupted) {
                    
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Session was interrupted."};
                    error = [NSError errorWithDomain:LZCameraErrorDomain
                                                code:LZCameraErrorSessionInterrupted
                                            userInfo:userInfo];
                }
                [self callBackVideoOnMainQueue:[self.videoFileOutputURL copy] error:error];
				[LZCameraToolkit deleteFile:self.videoFileOutputURL];
                [LZCameraToolkit deleteFile:self.videoFileOutputURL.URLByDeletingLastPathComponent];
            }
        }
	} else {
		[self captureVideoFileFinish:[self.videoFileOutputURL copy] error:error];
	}
}

// MARK: <AVCaptureVideoDataOutputSampleBufferDelegate>
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
}

// MARK: <AVCaptureMetadataOutputObjectsDelegate>
- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    LZMainQueueBlock(^{
        if (self.captureMetaDataCompletionHandler) {
            self.captureMetaDataCompletionHandler(metadataObjects, nil);
        }
    })
}

// MARK: - Private
/**
 执行代理方法

 @param selector SEL
 @param error NSError
 */
- (void)performDelegateSelectorIfSupported:(SEL)selector withObject:(NSError *)error {
    
    if ([self.delegate respondsToSelector:selector]) {
        
        if (error) {
            LZCameraLog(@"%@ %@", NSStringFromSelector(selector), error);
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:selector withObject:error];
#pragma clang diagnostic pop
    }
}

/**
 注册视频缩放监听
 */
- (void)regiesterObserverForVideoZoom {
    
    [[self activeCamera] addObserver:self
                          forKeyPath:LZCameraVideoZoomFactorKey
                             options:NSKeyValueObservingOptionNew
                             context:&LZCameraVideoZoomFactorContext];
    [[self activeCamera] addObserver:self
                          forKeyPath:LZCameraVideoRampingZoomKey
                             options:NSKeyValueObservingOptionNew
                             context:&LZCameraVideoRampingZoomContext];
}

/**
 移除视频缩放监听
 */
- (void)removeObserverForVideoZoom {
    
    [[self activeCamera] removeObserver:self forKeyPath:LZCameraVideoZoomFactorKey];
    [[self activeCamera] removeObserver:self forKeyPath:LZCameraVideoRampingZoomKey];
}

/**
 获取当前激活的摄像头

 @return AVCaptureDevice
 */
- (AVCaptureDevice *)activeCamera {
    return self.activeMediaInput.device;
}

/**
 获取备用摄像头

 @return AVCaptureDevice
 */
- (AVCaptureDevice *)inactiveCamera {
    
    AVCaptureDevice *camera = nil;
    if (self.cameraCount > 1) {
        
        if ([self activeCamera].position == AVCaptureDevicePositionBack) {
            camera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        } else {
            camera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
    }
    return camera;
}

/**
 获取相应位置的摄像头

 @param position AVCaptureDevicePosition
 @return AVCaptureDevice
 */
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        
        if (camera.position == position) {
            return camera;
        }
    }
    return nil;
}

/**
 最大缩放因子

 @return CGFloat
 */
- (CGFloat)maxZoomFactor {
    
    AVCaptureDevice *device = [self activeCamera];
    CGFloat maxZoomFactor = 0;
    if (@available(iOS 11, *)) {
        maxZoomFactor = device.maxAvailableVideoZoomFactor;
    } else {
        maxZoomFactor = device.activeFormat.videoMaxZoomFactor;
    }
    return MIN(maxZoomFactor, self.cameraConfig.maxCameraZoomFactor);
}

/**
 计算最大缩放因子

 @param zoomValue CGFloat
 @return CGFloat
 */
- (CGFloat)calculateMaxZoomFactorWithZoomValue:(CGFloat)zoomValue {
    
    CGFloat maxZoomFactor = [self maxZoomFactor];
    CGFloat zoomFactor = pow(maxZoomFactor, zoomValue);
    return zoomFactor > maxZoomFactor ? maxZoomFactor : zoomFactor;
}

/**
 当前视频缩放值

 @return CGFloat
 */
- (CGFloat)currentVideoZoomValue {
    
    CGFloat curZoomFactor = [self activeCamera].videoZoomFactor;
    CGFloat maxZoomFactor = [self maxZoomFactor];
    CGFloat value = log(curZoomFactor) / log(maxZoomFactor);
    return value;
}

/**
 主线程回调视频缩放值
 */
- (void)callBackVideoZoomValueOnMainQueue {
    
    CGFloat value = [self currentVideoZoomValue];
    LZMainQueueBlock(^{
        if (self.zoomCompletionHandler) {
            self.zoomCompletionHandler(value);
        }
    })
}

/**
 获取当前视频的方向

 @return AVCaptureVideoOrientation
 */
- (AVCaptureVideoOrientation)currentVideoOrientation {
    
    AVCaptureVideoOrientation orientation;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    return orientation;
}

/**
 图像保存到系统相册

 @param image UIImage
 */
- (void)writeImageToPhotosAlbum:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

/**
 图像保存到相册回调方法

 @param image UIImage
 @param error NSError
 @param contextInfo void *
 */
- (void)image:(UIImage *)image
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
	
	if (error) {
		[self performDelegateSelectorIfSupported:@selector(photosAlbumWriteFailedWithError:)
                                      withObject:error];
	} else {
		[self callBackStillImageOnMainQueue:image error:nil];
	}
}

/**
 主线程回调捕捉到的图片

 @param image UIImage
 @param error NSError
 */
- (void)callBackStillImageOnMainQueue:(UIImage *)image error:(NSError *)error {
	
    LZMainQueueBlock(^{
		if (self.captureStillImageCompletionHandler) {
            if (error) {
                LZCameraLog(@"%@", error);
            }
            self.captureStillImageCompletionHandler(image, error);
		}
	})
}

/**
 视频保存到相册

 @param videoURL NSURL
 */
- (void)writeVideoToPhotosAlbum:(NSURL *)videoURL {
	UISaveVideoAtPathToSavedPhotosAlbum(videoURL.relativePath, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
}

/**
 视频保存到相册的回调方法

 @param videoPath NSString
 @param error NSError
 @param contextInfo void *
 */
- (void)video:(NSString *)videoPath
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
	
	if (error) {
        [self performDelegateSelectorIfSupported:@selector(photosAlbumWriteFailedWithError:)
                                      withObject:error];
	} else {
		[self callBackVideoOnMainQueue:[NSURL fileURLWithPath:videoPath] error:error];
	}
}

/**
 捕捉视频完成

 @param fileURL NSURL
 @param error NSError
 */
- (void)captureVideoFileFinish:(NSURL *)fileURL error:(NSError *)error {
    
    if (self.cameraConfig.videoAutoWriteToAlbum) {
        [self writeVideoToPhotosAlbum:fileURL];
    } else {
        [self callBackVideoOnMainQueue:fileURL error:error];
    }
}

/**
 主线程回调录制的视频
 
 @param videoURL NSURL
 @param error NSError
 */
- (void)callBackVideoOnMainQueue:(NSURL *)videoURL error:(NSError *)error {
	
	LZMainQueueBlock(^{
		if (self.captureVideoCompletionHandler) {
			if (error) {
				LZCameraLog(@"%@", error);
			}
			self.captureVideoCompletionHandler(videoURL, error);
		}
	})
}

/**
 可用的元数据类型

 @param metaObjectTypes @[AVMetadataObjectType]
 @return NSArray
 */
- (NSArray *)availableMetadataObjectTypesForTypes:(NSArray<AVMetadataObjectType> *)metaObjectTypes {
    
    NSMutableArray *metaTypes = [NSMutableArray arrayWithArray:metaObjectTypes];
    NSArray *availableMetadataObjectTypes = self.metadataOutput.availableMetadataObjectTypes;
    for (AVMetadataObjectType type in metaObjectTypes) {
        
        if (![availableMetadataObjectTypes containsObject:type]) {
            [metaTypes removeObject:type];
        }
    }
    return [metaTypes copy];
}

/**
 配置元数据输出

 @param metaObjectTypes @[AVMetadataObjectType]
 @param error NSError **
 @return BOOL
 */
- (BOOL)configMetaDataOutputWith:(NSArray<AVMetadataObjectType> *)metaObjectTypes
                           error:(NSError **)error {
    
    if (self.metadataOutput) {
        
        [self.captureSession removeOutput:self.metadataOutput];
        self.metadataOutput = nil;
    }
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.captureSession canAddOutput:self.metadataOutput]) {
        
        [self.captureSession addOutput:self.metadataOutput];
        // 必须要先添加输出，再设置，否则必报错。无可用的类型
        self.metadataOutput.metadataObjectTypes = [self availableMetadataObjectTypesForTypes:metaObjectTypes];
        [self.metadataOutput setMetadataObjectsDelegate:self queue:LZMainQueue];
    } else {
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to meta data output."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddOutput
                                 userInfo:userInfo];
        LZMainQueueBlock(^{
            
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to meta data output."};
            NSError *error = [NSError errorWithDomain:LZCameraErrorDomain
                                         code:LZCameraErrorFailedToAddOutput
                                     userInfo:userInfo];
            if (self.captureMetaDataCompletionHandler) {
                if (error) {
                    LZCameraLog(@"%@", error);
                }
                self.captureMetaDataCompletionHandler(nil, error);
            }
        })
        return NO;
    }
    return YES;
}

@end
