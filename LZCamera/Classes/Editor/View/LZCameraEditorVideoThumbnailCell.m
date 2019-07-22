//
//  LZCameraEditorVideoThumbnailCell.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import "LZCameraEditorVideoThumbnailCell.h"

NSString * const LZEditVideoThumbnailCellID = @"LZCameraEditorVideoThumbnailCell";

@implementation LZCameraEditorVideoThumbnailCell

// MARK: - Initialization
- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.imgView.backgroundColor = [UIColor orangeColor];
}

@end
