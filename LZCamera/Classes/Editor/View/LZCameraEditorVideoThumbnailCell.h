//
//  LZCameraEditorVideoThumbnailCell.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 唯一标识 */
FOUNDATION_EXTERN NSString * const LZEditVideoThumbnailCellID;

@interface LZCameraEditorVideoThumbnailCell : UICollectionViewCell {
	@public
}

@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

NS_ASSUME_NONNULL_END
