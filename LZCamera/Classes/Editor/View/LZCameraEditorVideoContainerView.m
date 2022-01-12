//
//  LZCameraEditorVideoContainerView.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import "LZCameraEditorVideoContainerView.h"
#import "LZCameraEditorVideoThumbnailCell.h"
#import "UIImageView+LZTouchRect.h"

@interface LZCameraEditorVideoContainerView()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
	
    IBOutlet UIProgressView *progressView;
	IBOutlet UICollectionView *thumbnailCollectionView;
	IBOutlet UIView *leftClipView;
	IBOutlet NSLayoutConstraint *leftClipViewWidth;
	IBOutlet UIImageView *leftClipImgView;
	IBOutlet UIView *rightClipView;
	IBOutlet NSLayoutConstraint *rightClipViewWidth;
	IBOutlet UIImageView *rightClipImgView;
	IBOutlet UIView *lineView;
    IBOutlet UILabel *tipLabel;
}

@property (strong, nonatomic) NSMutableArray *datasource;

@property (assign, nonatomic) CGFloat widthPerUnit;
@property (assign, nonatomic) CGFloat secondPerUnit;
@property (assign, nonatomic) CMTime startTime;
@property (assign, nonatomic) CMTime endTime;
@property (assign, nonatomic) CMTime offsetTime;

@end
@implementation LZCameraEditorVideoContainerView

// MARK: - Lazy Loading
- (NSMutableArray *)datasource {
	
	if (nil == _datasource) {
		_datasource = [NSMutableArray array];
	}
	return _datasource;
}

// MARK: - Initialization
- (void)awakeFromNib {
	[super awakeFromNib];

	[self setupUI];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	
	CGPoint childP = [self convertPoint:point toView:leftClipImgView];
	if ([leftClipImgView pointInside:childP withEvent:event]) {
		return leftClipImgView;
	}
	
	childP = [self convertPoint:point toView:rightClipImgView];
	if ([rightClipImgView pointInside:childP withEvent:event]) {
		return rightClipImgView;
	}
	
	return nil;
}

// MARK: - Public
- (void)updateVideoThumbnails:(NSArray *)thumbnails
                     progress:(CGFloat)progress
					 complete:(BOOL)complete{
	
    [self updateThumbnailProgress:progress];
    
	if (complete) {
		
		self.startTime = kCMTimeZero;
		self.endTime = kCMTimeZero;
		self.offsetTime = kCMTimeZero;
		
		thumbnailCollectionView.scrollEnabled = YES;
		
		leftClipImgView.userInteractionEnabled = YES;
		rightClipImgView.userInteractionEnabled = YES;
        
        tipLabel.text = @"拖动剪辑框可裁剪视频";
	}
	
	if (thumbnails && thumbnails.count) {
		
        CGFloat perUnitWidth = thumbnailCollectionView.frame.size.width / self.videoMaximumDuration;
        CGFloat scale = thumbnails.count > self.videoMaximumDuration ? 1.0 : self.videoMaximumDuration / thumbnails.count;
        self.widthPerUnit = perUnitWidth * scale;
        self.secondPerUnit = self.duration.value / self.duration.timescale / thumbnails.count;
		
		[self.datasource removeAllObjects];
		[self.datasource addObjectsFromArray:thumbnails];
		[thumbnailCollectionView reloadData];
	}
}

- (void)updateProgressLine {
	
	lineView.hidden = NO;
	
	__block CGRect frame = lineView.frame;
	frame.origin.x = CGRectGetMaxX(leftClipView.frame);
	lineView.frame = frame;
	
	CMTimeRange timeRange = [self playTimeRange];
	CGFloat duration = timeRange.duration.value / timeRange.duration.timescale;
	UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear;
	[UIView animateWithDuration:duration
						  delay:.0
						options:options
					 animations:^{
		
						 frame.origin.x = CGRectGetMinX(self->rightClipView.frame);
						 self->lineView.frame = frame;
					 } completion:^(BOOL finished) {
					 }];
}

- (void)removeProgressLine {
	
	lineView.hidden = YES;
	CGRect frame = lineView.frame;
	frame.origin.x = CGRectGetMaxX(leftClipView.frame);
	lineView.frame = frame;
}

// MARK: - UI Action
- (IBAction)leftClipViewPanGesture:(UIPanGestureRecognizer *)sender {
	
    if (NO == sender.view.userInteractionEnabled) {
        return;
    }
	CGPoint point = [sender translationInView:thumbnailCollectionView];
	static CGFloat baseWidth = 10.0f;
	leftClipViewWidth.constant = baseWidth + point.x;
	if (leftClipViewWidth.constant + rightClipViewWidth.constant + 3 >= thumbnailCollectionView.frame.size.width) {
		leftClipViewWidth.constant = thumbnailCollectionView.frame.size.width - rightClipViewWidth.constant - 3;
	}
	CGFloat seconds = ((leftClipViewWidth.constant - 10) / self.widthPerUnit * self.secondPerUnit);
	if (seconds < 0) {
		seconds = 0;
	}
	CMTime time = CMTimeMake(seconds * self.duration.timescale, self.duration.timescale);
	self.startTime = time;
	
	if (sender.state == UIGestureRecognizerStateEnded) {
		baseWidth = leftClipViewWidth.constant;
	}
	if (leftClipViewWidth.constant < 10) {
		
		leftClipViewWidth.constant = 10;
		baseWidth = 10.0f;
	}
	[self preview];
}

- (IBAction)rightClipViewPanGesture:(UIPanGestureRecognizer *)sender {
	
    if (NO == sender.view.userInteractionEnabled) {
        return;
    }
	CGPoint point = [sender translationInView:thumbnailCollectionView];
	static CGFloat baseWidth = 10.0f;
	if (point.x < 0) {
		rightClipViewWidth.constant = fabs(-baseWidth + point.x);
	} else {
		rightClipViewWidth.constant = baseWidth - point.x;
	}
	if (leftClipViewWidth.constant + rightClipViewWidth.constant + 3 >= thumbnailCollectionView.frame.size.width) {
		rightClipViewWidth.constant = thumbnailCollectionView.frame.size.width - leftClipViewWidth.constant - 3;
	}
	CGFloat seconds = ((rightClipViewWidth.constant - 10) / self.widthPerUnit * self.secondPerUnit);
	if (seconds < 0) {
		seconds = 0;
	}
	CMTime time = CMTimeMake(seconds * self.duration.timescale, self.duration.timescale);
	self.endTime = time;
	
	if (sender.state == UIGestureRecognizerStateEnded) {
		baseWidth = rightClipViewWidth.constant;
	}
	if (rightClipViewWidth.constant < 10) {
		
		rightClipViewWidth.constant = 10;
		baseWidth = 10.0f;
	}
	[self preview];
}

// MARK: - Private
- (void)setupUI {
	
    progressView.progress = 0.0f;
    
	thumbnailCollectionView.scrollEnabled = NO;
    thumbnailCollectionView.layer.borderColor = [[UIColor colorWithRed:128.0f/255.0f green:198.0f/255.0f blue:5.0f/255.0f alpha:1.0f] CGColor];
    thumbnailCollectionView.layer.borderWidth = 2.5f;
	
	UIImage *clipImage = [self imageInBundle:@"editor_video_clip"];
	leftClipImgView.image = clipImage;
	leftClipImgView.userInteractionEnabled = NO;
	leftClipImgView.touchExtendInset = UIEdgeInsetsMake(-10, -20, -10, -1);
	rightClipImgView.image = clipImage;
	rightClipImgView.userInteractionEnabled = NO;
	rightClipImgView.touchExtendInset = UIEdgeInsetsMake(-10, -1, -10, -20);
	
    tipLabel.text = @"视频加载中……";
}

- (void)updateThumbnailProgress:(CGFloat)progress {
    
    LZCameraLog(@"视频缩略图进度:%f", progress);
    UIViewAnimationOptions options =
    UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear;
    [UIView animateWithDuration:0.5f
                          delay:.0
                        options:options
                     animations:^{
                         
                         BOOL animated = progress > 0;
                         [self->progressView setProgress:progress animated:animated];
                     } completion:^(BOOL finished) {
                     }];
    if (1 <= progress) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->progressView setProgress:0.0 animated:NO];
        });
    }
}

- (void)preview {
	if (self.TapPreviewClipCallback) {
		
		CMTimeRange timeRange = [self playTimeRange];
		self.TapPreviewClipCallback(timeRange);
	}
}

- (CMTimeRange)playTimeRange {
	
	CMTime startTime = CMTimeAdd(self.startTime, self.offsetTime);
	CMTime duration = CMTimeSubtract(CMTimeSubtract(self.duration , startTime), self.endTime);
	CMTimeRange timeRange = CMTimeRangeMake(startTime, duration);
#if DEBUG
	CMTimeShow(self.startTime);
	CMTimeShow(self.offsetTime);
	CMTimeShow(startTime);
	CMTimeShow(self.endTime);
	CMTimeRangeShow(timeRange);
#endif
	return timeRange;
}

- (UIImage *)imageInBundle:(NSString *)imageName {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
	return image;
}

// MARK: - Delegate
// MARK: <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView
	 numberOfItemsInSection:(NSInteger)section {
	return self.datasource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	LZCameraEditorVideoThumbnailCell *cell =
	[collectionView dequeueReusableCellWithReuseIdentifier:LZEditVideoThumbnailCellID
											  forIndexPath:indexPath];
	cell.imgView.image = [self.datasource objectAtIndex:indexPath.row];
	return cell;
}

// MARK: <UICollectionViewDelegateFlowLayout>
- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat height = thumbnailCollectionView.frame.size.height;
	return CGSizeMake(self.widthPerUnit, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 0.0f;
}

// MARK: <UIScrollViewDelegate>
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self removeProgressLine];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		
		CGFloat offsetX = scrollView.contentOffset.x;
		CMTimeValue seconds = offsetX / self.widthPerUnit * self.secondPerUnit;
		CMTime time = CMTimeMake(seconds * self.duration.timescale, self.duration.timescale);
		self.offsetTime = time;
		[self preview];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	CGFloat offsetX = scrollView.contentOffset.x;
	CMTimeValue seconds = offsetX / self.widthPerUnit * self.secondPerUnit;
	CMTime time = CMTimeMake(seconds * self.duration.timescale, self.duration.timescale);
	self.offsetTime = time;
	[self preview];
}

@end
