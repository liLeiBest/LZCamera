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

@interface LZCameraMediaViewController ()<LZCameraControllerDelegate>

@property (weak, nonatomic) IBOutlet LZCameraMediaPreviewView *mediaPreviewView;
@property (weak, nonatomic) IBOutlet LZCameraMediaStatusView *mediaStatusView;
@property (weak, nonatomic) IBOutlet LZCameraMediaModelView *mediaModelView;
@property (weak, nonatomic) IBOutlet UILabel *captureTipLabel;

@property (strong, nonatomic) LZCameraController *cameraController;

@end

@implementation LZCameraMediaViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.captureModel = LZCameraCaptureModelStillImageAndShortVideo;
    [self configCameraController];
    [self setupView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"LZCameraPreviewIdentifier"]) {
        
        LZCameraMediaPreviewViewController *ctr = segue.destinationViewController;
        ctr.previewObject = sender;
    }
}

- (void)setCaptureModel:(LZCameraCaptureModel)captureModel {
    _captureModel = captureModel;
    
    switch (captureModel) {
        case LZCameraCaptureModeStillImage:
            self.captureTipLabel.text = @"点击拍照";
            break;
        case LZCameraCaptureModelShortVideo:
            self.captureTipLabel.text = @"长按录像";
            break;
        case LZCameraCaptureModelStillImageAndShortVideo:
            self.captureTipLabel.text = @"点击拍照，长按录像";
            break;
        case LZCameraCaptureModelLongVideo:
            self.captureTipLabel.text = nil;
            break;
        default:
            break;
    }
    
    if (self.captureModel == LZCameraCaptureModelShortVideo || self.captureModel == LZCameraCaptureModelStillImageAndShortVideo) {
        self.maxDuration = 10.0f;
    }
}

// MARK: - Public
+ (instancetype)instance {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraMediaViewController"
                                                         bundle:LZCameraNSBundle(@"LZCameraMedia")];
    return storyboard.instantiateInitialViewController;
}

// MARK: - Private
/**
 配置摄像头
 */
- (void)configCameraController {
    
    LZCameraConfig *cameraConfig = [[LZCameraConfig alloc] init];
    if (self.captureModel == LZCameraCaptureModelShortVideo || self.captureModel == LZCameraCaptureModelStillImageAndShortVideo) {
        cameraConfig.maxVideoRecordedDuration = CMTimeMake(self.maxDuration, 1);
    }
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
    
    [self.cameraController videoRecordedDurationWithProgress:^(CMTime duration) {
        [self.mediaStatusView updateDurationTime:duration show:YES];
    }];
    
    [self.cameraController captureMetaDataObjectWithTypes:@[AVMetadataObjectTypeFace] completionHandler:^(NSArray<AVMetadataObject *> * _Nullable metadataObjects, NSError * _Nullable error) {
        
        NSMutableArray *faces = [NSMutableArray array];
        for (AVMetadataMachineReadableCodeObject *objct in metadataObjects) {
            
            if ([objct isKindOfClass:[AVMetadataFaceObject class]]) {
                
                AVMetadataFaceObject *face = (AVMetadataFaceObject *)objct;
                LZCameraLog(@"Face detected with ID: %li", (long)face.faceID);
                LZCameraLog(@"Face bounds: %@", NSStringFromCGRect(face.bounds));
                [faces addObject:objct];
            }
        }
        
        [self.mediaPreviewView detectFaces:faces];
    }];
}

/**
 设置视图
 */
- (void)setupView {
    
    [self performSelector:@selector(hideCaptureTip) withObject:nil afterDelay:1.0f];
    self.mediaPreviewView.singleTapToFocusEnable = self.cameraController.cameraSupportTapToFocus;
    self.mediaPreviewView.doubleTapToExposeEnable = self.cameraController.cameraSupportTapToExpose;
    self.mediaPreviewView.TapToFocusAtPointHandler = ^(CGPoint point) {
        [self.cameraController focusAtPoint:point];
    };
    self.mediaPreviewView.TapToExposeAtPointHandler = ^(CGPoint point) {
        [self.cameraController exposeAtPoint:point];
    };
    self.mediaPreviewView.TapToResetFocusAndExposure = ^{
        [self.cameraController resetFocusAndExposureMode];
    };
    self.mediaPreviewView.PinchToZoomHandler = ^(BOOL complete, BOOL magnify, CGFloat rampZoomValue) {
        
        if (magnify) {
             [self.cameraController rampZoomValue:1.0f];
        } else {
            [self.cameraController rampZoomValue:0.0f];
        }
        if (complete) {
            [self.cameraController cancelRampingZoom];
        }
    };
    
    self.mediaStatusView.captureModel = self.captureModel;
    self.mediaStatusView.TapToFlashModelHandler = ^(NSUInteger model) {
        self.cameraController.flashMode = AVCaptureFlashModeOn;
        self.cameraController.torchMode = AVCaptureTorchModeOn;
    };
    self.mediaStatusView.TapToSwitchCameraHandler = ^{
        
        [self.cameraController switchCameras];
        LZFlashVisualState state = LZFlashVisualStateOn;
        if (![self.cameraController cameraHasFlash] || ![self.cameraController cameraHasTorch]) {
            state = LZFlashVisualStateOff;
        }
        [self.mediaStatusView updateFlashVisualState:state];
    };
    
    self.mediaModelView.captureModel = self.captureModel;
    self.mediaModelView.TapToCancelCaptureHandler = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    self.mediaModelView.TapToCaptureImageHandler = ^(void (^ _Nonnull ComplteHandler)(void)) {
        
        [self.cameraController captureStillImage:^(UIImage * _Nonnull stillImage, NSError * _Nullable error) {
            
            NSString *path = [LZCameraNSBundle(@"LZCameraMedia") pathForResource:@"media_camera.wav" ofType:nil];
            NSURL *pathURL = [NSURL URLWithString:path];
            CFURLRef cfURL = CFBridgingRetain(pathURL);
            static SystemSoundID camera_sound = 0;
            AudioServicesCreateSystemSoundID(cfURL, &camera_sound);
            AudioServicesPlaySystemSound(camera_sound);
            AudioServicesDisposeSystemSoundID(camera_sound);
            [self performSegueWithIdentifier:@"LZCameraPreviewIdentifier" sender:stillImage];
            ComplteHandler();
        }];
    };
    self.mediaModelView.TapToCaptureVideoHandler = ^(BOOL began, BOOL end, void (^ _Nonnull ComplteHandler)(void)) {
        
        if (began) {
            
            NSString *path = [LZCameraNSBundle(@"LZCameraMedia") pathForResource:@"media_press.wav" ofType:nil];
            NSURL *pathURL = [NSURL URLWithString:path];
            CFURLRef cfURL = CFBridgingRetain(pathURL);
            static SystemSoundID camera_sound = 0;
            AudioServicesCreateSystemSoundID(cfURL, &camera_sound);
            AudioServicesPlaySystemSound(camera_sound);
            AudioServicesDisposeSystemSoundID(camera_sound);
            if (self.captureModel == LZCameraCaptureModelShortVideo || self.captureModel == LZCameraCaptureModelStillImageAndShortVideo) {
                self.mediaModelView.maxDuration = self.maxDuration;
            }
            [self.cameraController startVideoRecording:^(NSURL * _Nonnull videoURL, UIImage * _Nullable thumbnail, NSError * _Nullable error) {
                
                [self.mediaStatusView updateDurationTime:kCMTimeZero show:NO];
                [self performSegueWithIdentifier:@"LZCameraPreviewIdentifier" sender:videoURL];
                ComplteHandler();
            }];
        } else if (end) {
            
            [self.cameraController stopVideoRecording];
            ComplteHandler();
        }
    };
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
 隐藏捕捉提示
 */
- (void)hideCaptureTip {
    self.captureTipLabel.hidden = YES;
}

/**
 提示错误

 @param error NSError
 */
- (void)alertError:(NSError *)error {
    
    UIAlertController *alertCtr =
    [UIAlertController alertControllerWithTitle:@"ERROR"
                                        message:error.localizedDescription
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil]];
    [self presentViewController:alertCtr animated:YES completion:nil];
}


// MARK: - Delegate
// MARK: <LZCameraControllerDelegate>
- (void)cameraCaptureFailedWithError:(NSError *)error {
    if ([self.cameraController isVideoRecording]) {
        [self.cameraController stopVideoRecording];
    }
    [self alertError:error];
}

- (void)cameraConfigurationFailWithError:(NSError *)error {
    [self alertError:error];
}

- (void)photosAlbumWriteFailedWithError:(NSError *)error {
    [self alertError:error];
}

@end
