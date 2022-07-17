//
//  LZCameraMediaVideoPickerViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2020/9/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaVideoPickerViewController : UIImagePickerController

/** 短视频最长持续时间，单位：秒 */
@property (assign, nonatomic) CGFloat maxShortVideoDuration;
/// 选择完成回调
@property (nonatomic, copy) void (^pickCompleteCallback)(NSURL *URL);
/// 编辑完成回调
@property (nonatomic, copy) void (^editCompleteCallback)(NSURL *URL);


/**
 实例

 @return LZCameraMediaVideoPickerViewController
 */
+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END
