//
//  LZViewController.m
//  LZCamera
//
//  Created by lilei_hapy@163.com on 11/15/2018.
//  Copyright (c) 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZViewController.h"
#import "LZPreviewViewController.h"
#import <LZCamera/LZCameraCapture.h>

@interface LZViewController ()<LZCameraControllerDelegate>

@property (weak, nonatomic) IBOutlet LZCameraPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UIPinchGestureRecognizer *pichGestureRecognizer;
@property (strong, nonatomic) LZCameraController *cameraController;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 * 最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
    UITapGestureRecognizer *singleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureDidSingleTap:)];
    [self.captureBtn addGestureRecognizer:singleTap];
    UILongPressGestureRecognizer *longTap =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(captureDidLongTap:)];
    longTap.minimumPressDuration = 1.0f;
    [self.captureBtn addGestureRecognizer:longTap];
    [singleTap requireGestureRecognizerToFail:longTap];
    
    LZCameraConfig *cameraConfig = [[LZCameraConfig alloc] init];
//    cameraConfig.metaObjectTypes = @[AVMetadataObjectTypeFace];
//    cameraConfig.maxVideoRecordedDuration = CMTimeMake(10, 1);
//    cameraConfig.maxVideoRecordedFileSize = 102400000;
    self.cameraController = [LZCameraController cameraControllerWithConfig:cameraConfig];
    
    NSError *error;
    if ([self.cameraController setupSession:&error]) {
        
        self.cameraController.flashMode = AVCaptureFlashModeAuto;
        self.cameraController.torchMode = AVCaptureTorchModeAuto;
        [self.previewView setCaptureSesstion:self.cameraController.captureSession];
        [self.cameraController startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    if (!error) {
        
        self.previewView.singleTapToFocusEnable = self.cameraController.cameraSupportTapToFocus;
        self.previewView.doubleTapToExposeEnable = self.cameraController.cameraSupportTapToExpose;
        self.previewView.TappedToFocusAtPointHandler = ^(CGPoint point) {
            [self.cameraController focusAtPoint:point];
        };
        self.previewView.TappedToExposeAtPointHandler = ^(CGPoint point) {
            [self.cameraController exposeAtPoint:point];
        };
        self.previewView.TappedToResetFocusAndExposure = ^{
            [self.cameraController resetFocusAndExposureMode];
        };
        
        [self updateSession];
        [self updateTimeDisplay];
        __weak typeof(self) weakSelf = self;
        self.cameraController.zoomCompletionHandler = ^(CGFloat zoomValue) {
            weakSelf.zoomSlider.value = zoomValue;
        };
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"ShowStillImage"]) {
        
        LZPreviewViewController *ctr = segue.destinationViewController;
        ctr.preViewImage = (UIImage *)sender;
    }
}

// MARK: - UI Action
- (void)captureDidSingleTap:(UITapGestureRecognizer *)gestureRecognizer {
    
    self.captureBtn.enabled = NO;
    [self.cameraController captureStillImage:^(UIImage * _Nonnull stillImage, NSError * _Nullable error) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"camera.wav" ofType:nil];
        NSURL *pathURL = [NSURL URLWithString:path];
        CFURLRef cfURL = CFBridgingRetain(pathURL);
        static SystemSoundID camera_sound = 0;
        AudioServicesCreateSystemSoundID(cfURL, &camera_sound);
        AudioServicesPlaySystemSound(camera_sound);
        self.captureBtn.enabled = YES;
        [self performSegueWithIdentifier:@"ShowStillImage" sender:stillImage];
    }];
}

- (void)captureDidLongTap:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"press.wav" ofType:nil];
        NSURL *pathURL = [NSURL URLWithString:path];
        CFURLRef cfURL = CFBridgingRetain(pathURL);
        static SystemSoundID camera_sound = 1;
        AudioServicesCreateSystemSoundID(cfURL, &camera_sound);
        AudioServicesPlaySystemSound(camera_sound);
        [self.cameraController startVideoRecording:^(NSURL * _Nonnull videoURL, UIImage * _Nullable thumbnail, NSError * _Nullable error) {
            
            [self.cameraController stopVideoRecording];
            [self performSegueWithIdentifier:@"ShowStillImage" sender:thumbnail];
        }];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.cameraController stopVideoRecording];
    }
}

- (IBAction)pichDidTap:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    NSLog(@"==scale:%f velocity:%f", gestureRecognizer.scale, gestureRecognizer.velocity);
    
    if (gestureRecognizer.velocity < 0) {
        
        [self.cameraController rampZoomValue:0.0f];
    } else {
        [self.cameraController rampZoomValue:1.0f];
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.cameraController cancelRampingZoom];
    }
}

- (IBAction)swithCameraDidClick:(id)sender {
    
    [self.cameraController switchCameras];
}

- (IBAction)zoomToValue:(id)sender {
    [self.cameraController setZoomValue:self.zoomSlider.value];
}

- (IBAction)rampZoomToValue:(UIButton *)sender {
    [self.cameraController rampZoomValue:sender.tag];
}

- (IBAction)cancelZoomRamp:(id)sender {
    [self.cameraController cancelRampingZoom];
}

// MARK: - Private
- (void)updateTimeDisplay {
    
    [self.cameraController videoRecordedDurationWithProgress:^(CMTime duration) {
        
        NSUInteger time = (NSUInteger)CMTimeGetSeconds(duration);
        NSInteger hours = (time / 3600);
        NSInteger minutes = (time / 60) % 60;
        NSInteger seconds = time % 60 + 1;
        
        NSString *format = @"%02i:%02i:%02i";
        NSString *timeString = [NSString stringWithFormat:format, hours, minutes, seconds];
        self.timeLabel.text = timeString;
    }];
}

- (void)updateSession {
    
    [self.cameraController captureMetaDataObjectWithTypes:@[AVMetadataObjectTypeFace] completionHandler:^(NSArray<AVMetadataObject *> * _Nullable metadataObjects, NSError * _Nullable error) {
        
        NSMutableArray *faces = [NSMutableArray array];
        for (AVMetadataMachineReadableCodeObject *objct in metadataObjects) {
            
            if ([objct isKindOfClass:[AVMetadataFaceObject class]]) {
                
                AVMetadataFaceObject *face = (AVMetadataFaceObject *)objct;
                NSLog(@"Face detected with ID: %li", (long)face.faceID);
                NSLog(@"Face bounds: %@", NSStringFromCGRect(face.bounds));
                [faces addObject:objct];
            } else if ([objct isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                
                AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject *)objct;
                NSLog(@"Machine code: %@", code.stringValue);
            }
        }
        
        [self.previewView detectFaces:faces];
    }];
}

// MARK: - Delegate
- (void)cameraCaptureFailedWithError:(NSError *)error {
    [self.cameraController stopSession];
}

@end
