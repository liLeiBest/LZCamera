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
#import "LZCameraMediaVideoPickerViewController.h"
#import "LZCameraVideoEditorViewController.h"
#import <CoreServices/CoreServices.h>
#import <Photos/Photos.h>

@interface LZCameraMediaViewController ()<LZCameraControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet LZCameraMediaPreviewView *mediaPreviewView;
@property (weak, nonatomic) IBOutlet LZCameraMediaStatusView *mediaStatusView;
@property (weak, nonatomic) IBOutlet LZCameraMediaModelView *mediaModelView;
@property (weak, nonatomic) IBOutlet UILabel *captureTipLabel;

@property (strong, nonatomic) LZCameraController *cameraController;
@property (strong, nonatomic) UIImage *stillImage;
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
	[self registerObserver];
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
    LZCameraLog();
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (UIModalTransitionStyle)modalTransitionStyle {
    return UIModalTransitionStyleCoverVertical;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"LZCameraPreviewIdentifier"]) {
        
        LZCameraMediaPreviewViewController *ctr = segue.destinationViewController;
        ctr.previewImage = self.stillImage;
        ctr.previewVideoURL = self.videoURL;
		ctr.autoSaveToAlbum = self.autoSaveToAlbum;
        __weak typeof(self) weakSelf = self;
        ctr.TapToSureHandler = ^(UIImage * _Nullable editedImage, NSURL * _Nullable editedVideoURL, PHAsset * _Nullable asset) {
            typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.videoURL) {
                if (strongSelf.CameraVideoCompletionHandler) {
					
					UIImage *thumbnailImage = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:editedVideoURL];
                    strongSelf.CameraVideoCompletionHandler(thumbnailImage, editedVideoURL);
                }
            } else if (strongSelf.stillImage) {
                if (strongSelf.CameraImageCompletionHandler) {
                    strongSelf.CameraImageCompletionHandler(editedImage, asset);
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
- (void)configCameraController {
	
    LZCameraConfig *cameraConfig = [[LZCameraConfig alloc] init];
	cameraConfig.stillImageAutoWriteToAlbum = NO;
	cameraConfig.videoAutoWriteToAlbum = NO;
    cameraConfig.minVideoRecordedDuration = CMTimeMake(self.minVideoDuration, 1);
    if (self.captureModel == LZCameraCaptureModelShortVideo || self.captureModel == LZCameraCaptureModelStillImageAndShortVideo) {
        cameraConfig.maxVideoRecordedDuration = CMTimeMake(self.maxShortVideoDuration, 1);
    }
	cameraConfig.minVideoFreeDiskSpaceLimit = 150000000; // 150M
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
	self.mediaModelView.TapToAlbumVideoCallback = ^{
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf chooseVideoFromAlbum];
	};
    self.mediaModelView.TapToCaptureImageCallback = ^(void (^ _Nonnull ComplteHandler)(void)) {
        
        lzPlaySound(@"media_capture_image.wav", @"LZCameraMedia");
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.cameraController captureStillImage:^(UIImage * _Nonnull stillImage, NSError * _Nullable error) {
            if (stillImage) {
                
                strongSelf.stillImage = stillImage;
                strongSelf.videoURL = nil;
                NSString *segueIdentifier = @"LZCameraPreviewIdentifier";
                if ([strongSelf shouldPerformSegueWithIdentifier:segueIdentifier sender:nil]) {
                    [strongSelf performSegueWithIdentifier:segueIdentifier sender:nil];
                }
            }
            ComplteHandler();
        }];
    };
    self.mediaModelView.TapToCaptureVideoCallback = ^(BOOL began, BOOL end, void (^ _Nonnull ComplteHandler)(void)) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (began) {
			if (NO == strongSelf.captureTipLabel.hidden) {
				[strongSelf hideCaptureTip];
			}
            [strongSelf.mediaStatusView updateFlashVisualState:LZControlVisualStateOff];
            [strongSelf.mediaStatusView updateSwitchCameraVisualState:LZControlVisualStateOff];
            [strongSelf.cameraController startVideoRecording:^(NSURL * _Nonnull videoURL, NSError * _Nullable error) {
				
                [strongSelf controlFlashModelVisulState];
                [strongSelf controlSwitchCameraVisualState];
                [strongSelf.mediaStatusView updateDurationTime:kCMTimeZero];
                if (error) {
                    LZCameraLog(@"录制视频完成:%@", error);
                    [strongSelf alertMessage:error.localizedDescription handler:nil];
                } else {
                   
                    CMTime minTime = CMTimeMake(strongSelf.minVideoDuration, 1);
                    int32_t compareResult = CMTimeCompare(strongSelf.videoDuration, minTime);
                    if (compareResult >= 0) {
						
						strongSelf.stillImage = nil;
                        strongSelf.videoURL = videoURL;
                        NSString *segueIdentifier = @"LZCameraPreviewIdentifier";
                        if ([strongSelf shouldPerformSegueWithIdentifier:segueIdentifier sender:nil]) {
                            [strongSelf performSegueWithIdentifier:segueIdentifier sender:nil];
                        }
                    } else {
                        [strongSelf showCaputreTip:@"视频时间太短"];
                    }
                }
				ComplteHandler();
            }];
        } else if (end) {
            [strongSelf.cameraController stopVideoRecording];
        }
    };
}

- (void)chooseVideoFromAlbum {
    
	NSString *mediaType = (NSString *)kUTTypeMovie;
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	if ([self cameraSupportMedia:mediaType sourceType:sourceType]) {
        
		LZCameraMediaVideoPickerViewController *pickCtr = [[LZCameraMediaVideoPickerViewController alloc] init];
		pickCtr.sourceType = sourceType;
		pickCtr.mediaTypes = @[mediaType];
		pickCtr.allowsEditing = YES;
		pickCtr.delegate = self;
		[self presentViewController:pickCtr animated:YES completion:nil];
	}
}

- (BOOL)cameraSupportMedia:(NSString*)paramMediaType
				sourceType:(UIImagePickerControllerSourceType)paramSourceType {
	
	__block BOOL result=NO;
	if ([paramMediaType length]==0) {
		NSLog(@"Media type is empty.");
		return NO;
	}
	NSArray*availableMediaTypes=[UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
	[availableMediaTypes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString *mediaType = (NSString *)obj;
		if ([mediaType isEqualToString:paramMediaType]){
			result = YES;
			*stop= YES;
		}
	}];
	return result;
}

- (void)controlFlashModelVisulState {
    
    LZControlVisualState state = LZControlVisualStateOff;
    if (self.showFlashModeInStatusBar) {
        if ([self.cameraController cameraHasFlash] || [self.cameraController cameraHasTorch]) {
            state = LZControlVisualStateOn;
        }
    }
    [self.mediaStatusView updateFlashVisualState:state];
}

- (void)controlSwitchCameraVisualState {
    
    LZControlVisualState state = LZControlVisualStateOff;
    if (self.showSwitchCameraInStatusBar) {
        if ([self.cameraController canSwitchCameras]) {
            state = LZControlVisualStateOn;
        }
    }
    [self.mediaStatusView updateSwitchCameraVisualState:state];
}

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
	if ([self canPerformAction:@selector(hideCaptureTip) withSender:nil]) {
		[self performSelector:@selector(hideCaptureTip) withObject:nil afterDelay:2.0f];
	}
}

- (void)hideCaptureTip {
    self.captureTipLabel.hidden = YES;
}

- (void)registerObserver {
	[[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(cameraDone) name:LZCameraObserver_Complete object:nil];
}

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

- (void)photoAuthorizationJudge:(void (^)(BOOL authorized, NSError * __nullable error))handler {
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        if (handler) {
            handler(YES, nil);
        }
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusAuthorized: {
                    if (handler) {
                        handler(YES, nil);
                    }
                }
                    break;
                case PHAuthorizationStatusNotDetermined:
                    break;
                case PHAuthorizationStatusRestricted: {
                    if (handler) {
                        NSError *error =
                        [NSError errorWithDomain:LZCameraErrorDomain
                                            code:LZCameraErrorAuthorization
                                        userInfo:@{NSLocalizedDescriptionKey: @"PHAuthorizationStatusRestricted"}];
                        handler(NO, error);
                    }
                }
                    break;
                case PHAuthorizationStatusDenied: {
                    if (handler) {
                        NSError *error =
                        [NSError errorWithDomain:LZCameraErrorDomain
                                            code:LZCameraErrorAuthorization
                                        userInfo:@{NSLocalizedDescriptionKey: @"PHAuthorizationStatusDenied"}];
                        handler(NO, error);
                    }
                }
                    break;
                default:
                    if (handler) {
                        NSError *error =
                        [NSError errorWithDomain:LZCameraErrorDomain
                                            code:LZCameraErrorAuthorization
                                        userInfo:@{NSLocalizedDescriptionKey: @"PHAuthorizationStatusRestricted"}];
                        handler(NO, error);
                    }
                    break;
            }
        }
         ];
    }
}

- (void)saveVideoFromAssetURL:(NSURL *)assetURL
                       toURL:(NSURL *)fileURL
           completionCallback:(void (^)(NSError * __nullable error))handler{
    [self photoAuthorizationJudge:^(BOOL authorized, NSError * _Nullable error) {
        if (YES == authorized) {
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
            PHAsset *asset = fetchResult.firstObject;
            if (nil == asset) {
                NSError *error = [NSError errorWithDomain:LZCameraErrorDomain code:LZCameraErrorInvalideFileOutputURL userInfo:@{NSLocalizedDescriptionKey : @"Video do not exist!"}];
                if (handler) {
                    handler(error);
                }
                return;
            }
            NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
            PHAssetResource *resource = nil;
            for (PHAssetResource *assetRes in assetResources) {
                if (@available(iOS 9.1, *)) {
                    if (assetRes.type == PHAssetResourceTypePairedVideo
                        || assetRes.type == PHAssetResourceTypeVideo) {
                        resource = assetRes;
                        break;
                    }
                } else {
                    if (assetRes.type == PHAssetResourceTypeVideo) {
                        resource = assetRes;
                        break;
                    }
                }
            }
            [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:fileURL options:nil completionHandler: ^(NSError * _Nullable error) {
                if (handler) {
                    handler(error);
                }
            }];
        } else {
            if (handler) {
                handler(error);
            }
        }
    }];
}

- (void)showVideoEditCtr:(NSURL *)videoURL {
    
    self.videoURL = videoURL;
    LZCameraVideoEditorViewController *ctr = [LZCameraVideoEditorViewController instance];
    ctr.videoURL = videoURL;
    ctr.videoMaximumDuration = 60.0f;
    __weak typeof(self) weakSelf = self;
    ctr.VideoEditCallback = ^(NSURL * _Nonnull editedVideoURL) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.CameraVideoCompletionHandler) {
            
            UIImage *thumbnailImage = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:editedVideoURL];
            strongSelf.CameraVideoCompletionHandler(thumbnailImage, editedVideoURL);
        }
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ctr];
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

// MARK: - Observer
- (void)cameraDone {
	
	[self.cameraController stopSession];
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[LZCameraToolkit deleteFile:self.videoURL];
}

// MARK: - Delegate
// MARK: <LZCameraControllerDelegate>
- (void)cameraConfigurationFailWithError:(NSError *)error {
    [self alertMessage:error.localizedDescription handler:nil];
}

- (void)photosAlbumWriteFailedWithError:(NSError *)error {
    [self alertMessage:error.localizedDescription handler:nil];
}

// MARK: <UIImagePickerControllerDelegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
	
	[picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *destURL = [LZCameraToolkit generateUniqueAssetFileURL:LZCameraAssetTypeMov];
    
	NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    if (videoURL) {
        
        NSError *error = nil;
        NSFileManager *fileM = [NSFileManager defaultManager];
        BOOL success = [fileM copyItemAtURL:videoURL toURL:destURL error:&error];
        BOOL exist = [fileM fileExistsAtPath:destURL.relativePath];
        if (success && exist) {
            
            UIImage *thumbImg = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:destURL];
            if (thumbImg) {
                [self showVideoEditCtr:destURL];
            } else {
                [self alertMessage:@"不受支持的视频格式" handler:^(UIAlertAction *action) {
                }];
            }
        } else {
            [self alertMessage:error.localizedDescription handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    } else {
        
        videoURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        if (nil == videoURL) {
            if (@available(iOS 11, *)) {
                videoURL = [info objectForKey:UIImagePickerControllerPHAsset];
            }
        }
        if (nil != videoURL) {
            [self saveVideoFromAssetURL:videoURL toURL:destURL completionCallback:^(NSError * _Nullable error) {
                if (nil == error) {
                    [self showVideoEditCtr:destURL];
                } else {
                    [self alertMessage:error.localizedDescription handler:^(UIAlertAction *action) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                }
            }];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

@end
