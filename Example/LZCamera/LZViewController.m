//
//  LZViewController.m
//  LZCamera
//
//  Created by lilei_hapy@163.com on 11/15/2018.
//  Copyright (c) 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZViewController.h"
#import "LZTestViewController.h"
#import <LZCamera/LZCameraMedia.h>

@interface LZViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@end

@implementation LZViewController

// MARK: - Initialization
- (void)viewDidLoad {
	[super viewDidLoad];
	
}

// MARK: - UI Action
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
    ctr.CameraImageCompletionHandler = ^(UIImage * _Nonnull stillImage) {
        self.previewImgView.image = stillImage;
    };
    ctr.CameraVideoCompletionHandler = ^(UIImage * _Nonnull thumbnailImage, NSURL * _Nonnull videoURL) {
        self.previewImgView.image = thumbnailImage;
        [self compressVideo:videoURL];
    };
    [self.navigationController presentViewController:ctr animated:YES completion:nil];
}

- (void)compressVideo:(NSURL *)videoURL {
    
    NSString *videoSize = [NSString stringWithFormat:@"%@",[self getFileSize:videoURL.relativePath]];
    NSLog(@"视频压缩前文件大小:%@", videoSize);
    
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
                    NSString *videoSize = [NSString stringWithFormat:@"%@",[self getFileSize:outPutPath]];
                    NSLog(@"视频压缩后文件大小:%@", videoSize);
                });
            }
        }];
    }
}

/**
 获取文件大小
 */
- (NSString *) getFileSize:(NSString *)path {
    
    NSString *sizeText = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = fileDic.fileSize;
        filesize = 1.0*size/1024;
        
        if (size >= pow(10, 9)) { // size >= 1GB
            sizeText = [NSString stringWithFormat:@"%.2fGB", size / pow(10, 9)];
        } else if (size >= pow(10, 6)) { // 1GB > size >= 1MB
            sizeText = [NSString stringWithFormat:@"%.2fMB", size / pow(10, 6)];
        } else if (size >= pow(10, 3)) { // 1MB > size >= 1KB
            sizeText = [NSString stringWithFormat:@"%.2fKB", size / pow(10, 3)];
        } else { // 1KB > size
            sizeText = [NSString stringWithFormat:@"%lluB", size];
        }
    } else {
        NSLog(@"找不到文件");
    }
    return sizeText;
}


@end
