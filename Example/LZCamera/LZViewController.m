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

/** 视频播放器 */
@property (strong, nonatomic) LZCameraPlayer *videoPlayer;
@property (strong, nonatomic) NSURL *videoURL;

@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.videoPlayer pause];
}

// MARK: - UI Action
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	
	NSDictionary *attrubutes = @{NSFontAttributeName : [UIFont systemFontOfSize:30],
								 NSForegroundColorAttributeName : [UIColor whiteColor],
								 };
	NSAttributedString *attributedString =
	[[NSAttributedString alloc] initWithString:@"猜猜我是谁猜猜我是谁猜猜我是谁猜猜我是谁猜猜我是谁猜猜我是谁" attributes:attrubutes];
	UIImage *image = [UIImage imageNamed:@"editor_origin_music"
								inBundle:[NSBundle mainBundle]
		   compatibleWithTraitCollection:nil];
	[LZCameraToolkit watermarkForVideoAsset:self.videoURL
							  watermarkText:attributedString
							   textLocation:LZCameraWatermarkLocationLeftTop
							 watermarkImage:image
							  imageLocation:LZCameraWatermarkLocationLeftTop
						  completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
		
							  self.videoURL = outputFileURL;
							  [self buildVideoPlayer];
						  }];
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
		strongSelf.videoURL = videoURL;
        strongSelf.previewImgView.image = thumbnailImage;
		NSString *videosize = [LZCameraToolkit sizeForFile:videoURL.relativePath];
		strongSelf.messageLabel.text = [NSString stringWithFormat:@"视频文件大小:%@", videosize];
		[strongSelf buildVideoPlayer];
    };
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

- (void)buildVideoPlayer {
	
	if (self.videoPlayer) {
		
		[self.videoPlayer pause];
		[self.videoPlayer.playerLayer removeFromSuperlayer];
	}
	self.videoPlayer = [LZCameraPlayer playerWithURL:self.videoURL];
	AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
	self.videoPlayer.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	[self.view.layer insertSublayer:self.videoPlayer.playerLayer above:self.previewImgView.layer];
	[self.videoPlayer play];
}
@end
