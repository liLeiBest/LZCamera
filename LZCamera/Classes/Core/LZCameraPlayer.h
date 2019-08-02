//
//  LZCameraPlayer.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraPlayer : NSObject

/** 视频地址 */
@property (nonatomic, strong) NSURL *videoURL;
/** 播放区间，默认完整播放 */
@property (assign, nonatomic) CMTimeRange timeRange;
/** 音量 ,0.0~1.0 */
@property (assign, nonatomic) CGFloat volume;
/** 播放器视图 */
@property (strong, nonatomic, readonly) AVPlayerLayer *playerLayer;
/** 播放结束回调 */
@property (copy, nonatomic) void (^playToEndCallback)(void);


/**
 实例

 @param URL 视频地址
 @return LZCameraPlayer
 */
+ (instancetype)playerWithURL:(NSURL *)URL;

/**
 播放
 */
- (void)play;

/**
 暂停
 */
- (void)pause;

@end

NS_ASSUME_NONNULL_END
