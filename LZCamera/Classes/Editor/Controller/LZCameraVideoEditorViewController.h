//
//  LZCameraVideoEditorViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraVideoEditorViewController : UIViewController

/** 预览图片 */
@property (strong, nonatomic) UIImage *previewImage;
/** 视频文件地址 */
@property (strong, nonatomic) NSURL *videoURL;
/** 裁剪完成回调 */
@property (copy, nonatomic) void (^VideoClipCallback)(NSURL *videoUrl);
/** 最长时间，默认为 10 秒，设置为 0 不做设置 */
@property(nonatomic) NSTimeInterval videoMaximumDuration;

/**
 实例
 
 @return LZCameraVideoEditorViewController
 */
+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END
