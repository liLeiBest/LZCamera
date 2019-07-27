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
#import <LZCamera/LZCameraToastViewController.h>

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
	
	[LZCameraToast showMessage:@"处理中……"];
	[LZCameraToast hideAfterDelay:2 completionHandler:^{
		NSLog(@"提示关闭了");
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
        NSString *size = [strongSelf calulateImageFileSize:stillImage];
        strongSelf.messageLabel.text = [NSString stringWithFormat:@"图片的大小:%@", size];
    };
    ctr.CameraVideoCompletionHandler = ^(UIImage * _Nonnull thumbnailImage, NSURL * _Nonnull videoURL) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.previewImgView.image = thumbnailImage;
        [strongSelf compressVideo:videoURL];
    };
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

- (void)compressVideo:(NSURL *)videoURL {
    
    NSString *videoSizeBefore = [NSString stringWithFormat:@"%@",[self getFileSize:videoURL.relativePath]];
    
    // 通过文件的 url 获取到这个文件的资源
    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    // 用 AVAssetExportSession 这个类来导出资源中的属性
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    // 导出属性是否包含低分辨率
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        // 通过资源（AVURLAsset）来定义 AVAssetExportSession，得到资源属性来重新打包资源 （AVURLAsset, 将某一些属性重新定义
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        // 设置导出文件的存放路径
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        NSDate *date = [[NSDate alloc] init];
        NSString *outPutPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"output-%@.mp4",[formatter stringFromDate:date]]];
        exportSession.outputURL = [NSURL fileURLWithPath:outPutPath];
        // 是否对网络进行优化
        exportSession.shouldOptimizeForNetworkUse = true;
        // 转换成MP4格式
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        // 开始导出,导出后执行完成的block
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            // 如果导出的状态为完成
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 更新一下显示包的大小
                    NSString *videoSizeAfter = [NSString stringWithFormat:@"%@",[self getFileSize:outPutPath]];
                    self.messageLabel.text = [NSString stringWithFormat:@"视频压缩前文件大小:%@\n视频压缩后文件大小:%@", videoSizeBefore, videoSizeAfter];
                });
            }
        }];
    }
}

/**
 获取文件大小

 @param path NSString
 @return NSString
 */
- (NSString *) getFileSize:(NSString *)path {
    
    NSString *sizeText = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];
        unsigned long long size = fileDic.fileSize;
        if (size >= pow(10, 9)) { // size >= 1GB
            sizeText = [NSString stringWithFormat:@"%.2fGB", size / pow(10, 9)];
        } else if (size >= pow(10, 6)) { // 1GB > size >= 1MB
            sizeText = [NSString stringWithFormat:@"%.2fMB", size / pow(10, 6)];
        } else if (size >= pow(10, 3)) { // 1MB > size >= 1KB
            sizeText = [NSString stringWithFormat:@"%.2fKB", size / pow(10, 3)];
        } else { // 1KB > size
            sizeText = [NSString stringWithFormat:@"%.2lluB", size];
        }
    } else {
        NSLog(@"找不到文件");
    }
    return sizeText;
}


/**
 计算图片的大小

 @param image UIImage
 @return NSString
 */
- (NSString *)calulateImageFileSize:(UIImage *)image {
    
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 0.5);
    }
    double dataLength = [data length] * 1.0;
    NSArray *typeArray = @[@"B",@"KB",@"MB",@"GB"];
    NSInteger index = 0;
    while (dataLength > 1000) {
        dataLength /= 1000.0;
        index ++;
    }
    return [NSString stringWithFormat:@"%.3f%@", dataLength, typeArray[index]];
}

@end
