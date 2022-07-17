//
//  LZCameraMediaPreviewViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaPreviewViewController : UIViewController

/** 短视频最长持续时间，单位：秒 */
@property (assign, nonatomic) CGFloat maxShortVideoDuration;
/** 预览图片 */
@property (strong, nonatomic) UIImage *previewImage;
/** 预览视频地址 */
@property (strong, nonatomic) NSURL *previewVideoURL;
/** 是否自动保存到相册，默认：YES，自动存入相册 */
@property (assign, nonatomic) BOOL autoSaveToAlbum;
/** 确定选择回调 */
@property (copy, nonatomic) void(^TapToSureHandler)(UIImage * _Nullable editedImage, NSURL * _Nullable editedVideoURL, PHAsset * _Nullable asset);

@end

NS_ASSUME_NONNULL_END
