//
//  LZCameraEditorMusicThumbnailCell.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/23.
//

#import <UIKit/UIKit.h>
@class LZCameraEditorMusicModel;

NS_ASSUME_NONNULL_BEGIN

/** 唯一标识 */
FOUNDATION_EXTERN NSString * const LZEditMusicThumbnailCellID;

@interface LZCameraEditorMusicThumbnailCell : UICollectionViewCell

@property (strong, nonatomic) LZCameraEditorMusicModel *musicModel;

@end

NS_ASSUME_NONNULL_END
