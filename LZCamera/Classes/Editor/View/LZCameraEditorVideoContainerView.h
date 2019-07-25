//
//  LZCameraEditorVideoContainerView.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraEditorVideoContainerView : UIView

/** 最长时间，默认为 10 秒，设置为 0 不做设置 */
@property(nonatomic) NSTimeInterval videoMaximumDuration;
/** 时间 */
@property (assign, nonatomic) CMTime duration;
/** 预览裁剪回调 */
@property (copy, nonatomic) void (^TapPreviewClipCallback)(CMTimeRange timeRange);


/**
 更新缩略图

 @param thumbnails NSArray
 */
- (void)updateVideoThumbnails:(NSArray *)thumbnails;

/**
 更新进度条
 */
- (void)updateProgressLine;

/**
 移除进度条
 */
- (void)removeProgressLine;

@end

NS_ASSUME_NONNULL_END
