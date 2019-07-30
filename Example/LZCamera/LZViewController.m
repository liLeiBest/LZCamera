//
//  LZViewController.m
//  LZCamera
//
//  Created by lilei_hapy@163.com on 11/15/2018.
//  Copyright (c) 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZViewController.h"
#import "LZTestViewController.h"
#import <LZCamera/LZCamera.h>

@interface LZViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
}

// MARK: - UI Action
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	
}

- (IBAction)scanCodeDidClick:(id)sender {
    
    LZCameraCodeViewController *ctr = [LZCameraCodeViewController instance];
    NSArray *types = @[AVMetadataObjectTypeEAN13Code,
                       AVMetadataObjectTypeEAN8Code,
                       AVMetadataObjectTypeCode128Code,
                       AVMetadataObjectTypeCode39Code,
                       AVMetadataObjectTypeQRCode,
                       AVMetadataObjectTypeAztecCode,
                       AVMetadataObjectTypeUPCECode];
    [ctr detectCodeTyps:types completionHandler:^(NSArray<NSString *> *codeArray, NSError *error, void (^CompleteHandler)(void)) {
        
        NSString *codeString = [codeArray lastObject];
        self.messageLabel.text = codeString;
        if (CompleteHandler) {
            CompleteHandler();
        }
    }];
    [self.navigationController pushViewController:ctr animated:YES];
}

- (IBAction)rightCaptureStillImageDidClick:(id)sender {
    [self presentCameraMediaViewControlWithCaputreModel:LZCameraCaptureModeStillImage];
}

- (IBAction)rightCaptureShortVideoDidClick:(id)sender {
   [self presentCameraMediaViewControlWithCaputreModel:LZCameraCaptureModelShortVideo];
}

- (IBAction)rightCaptureStillImageAndShortVideoDidClick:(id)sender {
    [self presentCameraMediaViewControlWithCaputreModel:LZCameraCaptureModelStillImageAndShortVideo];
}

- (IBAction)rightCaptureLongVideoDidClick:(id)sender {
    [self presentCameraMediaViewControlWithCaputreModel:LZCameraCaptureModelLongVideo];
}

// MARK: - Private
- (void)presentCameraMediaViewControlWithCaputreModel:(LZCameraCaptureModel)caputreModel {
    
    LZCameraMediaViewController *ctr = [LZCameraMediaViewController instance];
    ctr.captureModel = caputreModel;
	ctr.showFlashModeInStatusBar = NO;
	ctr.maxShortVideoDuration = 60.0f;
    __weak typeof(self) weakSelf = self;
    ctr.CameraImageCompletionHandler = ^(UIImage * _Nonnull stillImage) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.previewImgView.image = stillImage;
        NSString *size = [LZCameraToolkit sizeForImage:stillImage];
        strongSelf.messageLabel.text = [NSString stringWithFormat:@"图片的大小:%@", size];
    };
    ctr.CameraVideoCompletionHandler = ^(UIImage * _Nonnull thumbnailImage, NSURL * _Nonnull videoURL) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.previewImgView.image = thumbnailImage;
		NSString *videoSizeBefore = [LZCameraToolkit sizeForFile:videoURL.relativePath];
		[LZCameraToolkit exportVideoAsset:videoURL
							   presetName:AVAssetExportPresetMediumQuality
						completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
			
							// 更新一下显示包的大小
							NSString *videoSizeAfter = [LZCameraToolkit sizeForFile:videoURL.relativePath];
							strongSelf.messageLabel.text = [NSString stringWithFormat:@"视频压缩前文件大小:%@\n视频压缩后文件大小:%@", videoSizeBefore, videoSizeAfter];
						}];
    };
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

@end
