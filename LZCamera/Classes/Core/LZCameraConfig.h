//
//  LZCameraConfig.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraConfig : NSObject

/** 元数据类型 */
@property (strong, nonatomic) NSArray<AVMetadataObjectType> *metaObjectTypes;
/** 图片是否保存到相册，默认：YES，自动存入相册 */
@property (assign, nonatomic) BOOL stillImageAutoWriteToAlbum;
/** 视频是否保存到相册，默认：YES，自动存入相册 */
@property (assign, nonatomic) BOOL videoAutoWriteToAlbum;
/** 图像缩放速率，默认：1.2f */
@property (assign, nonatomic) CGFloat cameraZoomRate;
/** 图像最大缩放因子，默认：3.0f */
@property (assign, nonatomic) CGFloat maxCameraZoomFactor;
/** 视频最短录制时间，默认：无限制 */
@property (assign, nonatomic) CMTime minVideoRecordedDuration;
/** 视频最长录制时间，默认：无限制 */
@property (assign, nonatomic) CMTime maxVideoRecordedDuration;
/** 视频文件最大限制，单位:bytes，默认：无限制 */
@property (assign, nonatomic) int64_t maxVideoRecordedFileSize;
/** 硬盘最小空间限制，单位:bytes，默认：无限制 */
@property (assign, nonatomic) int64_t minVideoFreeDiskSpaceLimit;

@end

NS_ASSUME_NONNULL_END
