//
//  LZCameraEditorVideoContainerView.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import "LZCameraEditorVideoContainerView.h"
#import "LZCameraEditorVideoThumbnailCell.h"

@interface LZCameraEditorVideoContainerView()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
	
	IBOutlet UICollectionView *thumbnailCollectionView;
	IBOutlet UIView *leftClipView;
	IBOutlet NSLayoutConstraint *leftClipViewWidth;
	IBOutlet UIImageView *leftClipImgView;
	IBOutlet UIView *rightClipView;
	IBOutlet NSLayoutConstraint *rightClipViewWidth;
	IBOutlet UIImageView *rightClipImgView;
	IBOutlet UIButton *cancelBtn;
	IBOutlet UIButton *sureBtn;
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

// MARK: - Public
- (void)updateVideoThumbnails:(NSArray *)thumbnails {
	
	self.startTime = kCMTimeZero;
	self.endTime = kCMTimeZero;
	
	leftClipImgView.userInteractionEnabled = YES;
	rightClipImgView.userInteractionEnabled = YES;
	
	if (0 == self.videoMaximumDuration) {
		
		self.widthPerUnit =thumbnailCollectionView.frame.size.width / thumbnails.count;
		self.secondPerUnit = self.duration.value / self.duration.timescale / thumbnails.count;
	} else {
		
		CGFloat perUnitWidth = thumbnailCollectionView.frame.size.width / self.videoMaximumDuration;
		CGFloat scale = thumbnails.count > self.videoMaximumDuration ? 1.0 : self.videoMaximumDuration / thumbnails.count;
		self.widthPerUnit = perUnitWidth * scale;
		self.secondPerUnit = 1.0f;
	}
	
	[self.datasource removeAllObjects];
	[self.datasource addObjectsFromArray:thumbnails];
	[thumbnailCollectionView reloadData];
}

// MARK: - UI Action
- (IBAction)cancelDidClick:(id)sender {
	if (self.TapCancelClipCallback) {
		self.TapCancelClipCallback();
	}
}

- (IBAction)previewDidClick:(id)sender {
	[self preview];
}

- (IBAction)sureDidClick:(id)sender {
	
	if (self.TapClipCallback) {
		
		CMTime duration = CMTimeSubtract(CMTimeSubtract(self.duration , self.startTime), self.endTime);
		CMTimeRange timeRange = CMTimeRangeMake(self.startTime, duration);
		CMTimeRangeShow(timeRange);
		self.TapClipCallback(timeRange);
	}
}

- (IBAction)leftClipViewPanGesture:(UIPanGestureRecognizer *)sender {
	
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
	[self preview];
	
	if (leftClipViewWidth.constant < 10) {
		
		leftClipViewWidth.constant = 10;
		baseWidth = 10.0f;
		return;
	}
	if (sender.state == UIGestureRecognizerStateEnded) {
		baseWidth = leftClipViewWidth.constant;
	}
}

- (IBAction)rightClipViewPanGesture:(UIPanGestureRecognizer *)sender {
	
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
	[self preview];
	
	if (rightClipViewWidth.constant < 10) {
		
		rightClipViewWidth.constant = 10;
		baseWidth = 10.0f;
		return;
	}
	if (sender.state == UIGestureRecognizerStateEnded) {
		baseWidth = rightClipViewWidth.constant;
	}
}

// MARK: - Private
- (void)setupUI {
	
	UIImage *clipImage = [self imageInBundle:@"editor_video_clip"];
	leftClipImgView.image = clipImage;
	leftClipImgView.userInteractionEnabled = NO;
	rightClipImgView.image = clipImage;
	rightClipImgView.userInteractionEnabled = NO;
	
	thumbnailCollectionView.layer.borderColor = [UIColor whiteColor].CGColor;
	thumbnailCollectionView.layer.borderWidth = 2.0f;
}

- (void)preview {
	
	if (self.TapPreviewClipCallback) {
		
		CMTimeShow(self.startTime);
		CMTimeShow(self.offsetTime);
		CMTime startTime = CMTimeAdd(self.startTime, self.offsetTime);
		CMTimeShow(startTime);
		CMTimeShow(self.endTime);
		CMTime duration = CMTimeSubtract(CMTimeSubtract(self.duration , startTime), self.endTime);
		CMTimeRange timeRange = CMTimeRangeMake(startTime, duration);
		CMTimeRangeShow(timeRange);
		self.TapPreviewClipCallback(timeRange);
	}
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
}

@end
