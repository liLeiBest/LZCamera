//
//  LZCameraVideoEditMusicViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraVideoEditMusicViewController : UIViewController

/** 视频文件地址 */
@property (strong, nonatomic) NSURL *videoURL;
/** 循环播放的区间 */
@property (assign, nonatomic) CMTimeRange timeRange;
/** 视频编辑回调 */
@property (copy, nonatomic) void (^VideoEditCallback)(NSURL *videoURL, UIImage *previewImage);


/**
 实例
 
 @return LZCameraVideoEditMusicViewController
 */
+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END
