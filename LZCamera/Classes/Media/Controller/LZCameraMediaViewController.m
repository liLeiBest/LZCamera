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

/**
 播放声音
 
 @param soundName 声音名称
 */
void lzPlaySound(NSString *soundName) {
    
    NSString *path = [LZCameraNSBundle(@"LZCameraMedia") pathForResource:soundName ofType:nil];
    NSURL *pathURL = [NSURL URLWithString:path];
    CFURLRef cfURL = CFBridgingRetain(pathURL);
    static SystemSoundID camera_sound = 0;
    AudioServicesCreateSystemSoundID(cfURL, &camera_sound);
    AudioServicesPlaySystemSound(camera_sound);
    AudioServicesDisposeSystemSoundID(camera_sound);
}

@interface LZCameraMediaViewController ()<LZCameraControllerDelegate>

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
        self.minShortVideoDuration = 3.0f;
        self.detectFaces = NO;
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
        ctr.target = self;
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
    
    __weak typeof(self) weakSelf = self;
    
    LZCameraConfig *cameraConfig = [[LZCameraConfig alloc] init];
    if (self.captureModel == LZCameraCaptureModelShortVideo || self.captureModel == LZCameraCaptureModelStillImageAndShortVideo) {
        cameraConfig.maxVideoRecordedDuration = CMTimeMake(self.maxShortVideoDuration, 1);
    }
    self.cameraController = [LZCameraController cameraControllerWithConfig:cameraConfig];
    self.cameraController.delegate = self;
    NSError *error;
    if ([self.cameraController setupSession:&error]) {
        
        self.cameraController.flashMode = AVCaptureFlashModeAuto;
        self.cameraController.torchMode = AVCaptureTorchModeAuto;
        [self.mediaPreviewView setCaptureSesstion:self.cameraController.captureSession];
        self.mediaPreviewView.singleTapToFocusEnable = self.cameraController.cameraSupportTapToFocus;
        self.mediaPreviewView.doubleTapToExposeEnable = self.cameraController.cameraSupportTapToExpose;
        [self.cameraController startSession];
    } else {
        LZCameraLog(@"CameraController config error: %@", [error localizedDescription]);
    }
    [self.cameraController videoRecordedDurationWithProgress:^(CMTime duration) {
        
        LZCameraLog(@"11111111111更新时间");
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.videoDuration = duration;
        [strongSelf.mediaStatusView updateDurationTime:duration];
        [strongSelf.mediaModelView updateDurationTime:duration];
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
                    [faces addObject:objct];
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
    [self.mediaStatusView updateFlashVisualState:self.showFlashModeInStatusBar ? LZControlVisualStateOn : LZControlVisualStateOff];
    [self.mediaStatusView updateSwitchCameraVisualState:self.showSwitchCameraInStatusBar ? LZControlVisualStateOn : LZControlVisualStateOff];
    self.mediaStatusView.captureModel = self.captureModel;
    self.mediaStatusView.TapToFlashModelHandler = ^(NSUInteger model) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.cameraController.flashMode = model;
        strongSelf.cameraController.torchMode = model;
    };
    self.mediaStatusView.TapToSwitchCameraHandler = ^{
        
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.cameraController switchCameras];
        if (strongSelf.showFlashModeInStatusBar) {
            
            LZControlVisualState state = LZControlVisualStateOn;
            if (![strongSelf.cameraController cameraHasFlash] || ![strongSelf.cameraController cameraHasTorch]) {
                state = LZControlVisualStateOff;
            }
            [strongSelf.mediaStatusView updateFlashVisualState:state];
        }
    };
    
    // 拍照视图
    self.mediaModelView.captureModel = self.captureModel;
    self.mediaModelView.TapToCancelCaptureHandler = ^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    self.mediaModelView.TapToCaptureImageHandler = ^(void (^ _Nonnull ComplteHandler)(void)) {
        
        lzPlaySound(@"media_camera.wav");
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.cameraController captureStillImage:^(UIImage * _Nonnull stillImage, NSError * _Nullable error) {
            
            strongSelf.previewImage = stillImage;
            strongSelf.videoURL = nil;
            [strongSelf performSegueWithIdentifier:@"LZCameraPreviewIdentifier" sender:stillImage];
            ComplteHandler();
        }];
    };
    self.mediaModelView.TapToCaptureVideoHandler = ^(BOOL began, BOOL end, void (^ _Nonnull ComplteHandler)(void)) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        if (began) {
            
            strongSelf.mediaModelView.maxDuration = strongSelf.maxShortVideoDuration;
            [strongSelf.cameraController startVideoRecording:^(NSURL * _Nonnull videoURL, UIImage * _Nullable thumbnail, NSError * _Nullable error) {
                
                LZCameraLog(@"11111111111停止了");
                [strongSelf.mediaStatusView updateDurationTime:kCMTimeZero];
                CMTime minTime = CMTimeMake(strongSelf.minShortVideoDuration, 1);
                int32_t compareResult = CMTimeCompare(strongSelf.videoDuration, minTime);
                if (compareResult >= 0) {
                    
                    strongSelf.previewImage = thumbnail;
                    strongSelf.videoURL = videoURL;
                    [strongSelf performSegueWithIdentifier:@"LZCameraPreviewIdentifier" sender:videoURL];
                } else {
                    
                    NSError *error;
                    NSFileManager *fileM = [NSFileManager defaultManager];
                    [fileM removeItemAtURL:videoURL error:&error];
                    if (error) {
                        LZCameraLog(@"删除文件失败:%@", error);
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
 配置捕捉提示
 */
- (void)configCaptureTipView {
    
    switch (self.captureModel) {
        case LZCameraCaptureModeStillImage:
            self.captureTipLabel.text = @"轻触拍照";
            break;
        case LZCameraCaptureModelShortVideo:
            self.captureTipLabel.text = @"按住录像";
            break;
        case LZCameraCaptureModelStillImageAndShortVideo:
            self.captureTipLabel.text = @"轻触拍照，按住录像";
            break;
        case LZCameraCaptureModelLongVideo:
            self.captureTipLabel.text = nil;
            break;
        default:
            break;
    }
    
    [self performSelector:@selector(hideCaptureTip) withObject:nil afterDelay:1.0f];
}

/**
 隐藏捕捉提示
 */
- (void)hideCaptureTip {
    self.captureTipLabel.hidden = YES;
}

// 压缩视频
- (void)compressVideo:(id)sender
{
//    NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *savePath=[cachePath stringByAppendingPathComponent:MOVIEPATH];
//    NSURL *saveUrl=[NSURL fileURLWithPath:savePath];
//
//    // 通过文件的 url 获取到这个文件的资源
//    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:saveUrl options:nil];
//    // 用 AVAssetExportSession 这个类来导出资源中的属性
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
//
//    // 压缩视频
//    if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) { // 导出属性是否包含低分辨率
//        // 通过资源（AVURLAsset）来定义 AVAssetExportSession，得到资源属性来重新打包资源 （AVURLAsset, 将某一些属性重新定义
//        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetLowQuality];
//        // 设置导出文件的存放路径
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
//        NSDate    *date = [[NSDate alloc] init];
//        NSString *outPutPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"output-%@.mp4",[formatter stringFromDate:date]]];
//        exportSession.outputURL = [NSURL fileURLWithPath:outPutPath];
//
//        // 是否对网络进行优化
//        exportSession.shouldOptimizeForNetworkUse = true;
//
//        // 转换成MP4格式
//        exportSession.outputFileType = AVFileTypeMPEG4;
//
//        // 开始导出,导出后执行完成的block
//        [exportSession exportAsynchronouslyWithCompletionHandler:^{
//            // 如果导出的状态为完成
//            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    // 更新一下显示包的大小
//                    self.videoSize.text = [NSString stringWithFormat:@"%f MB",[self getfileSize:outPutPath]];
//                });
//            }
//        }];
//    }
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
