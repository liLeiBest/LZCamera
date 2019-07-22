//
//  LZCameraVideoEditorViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import "LZCameraVideoEditorViewController.h"
#import "LZCameraEditorVideoContainerView.h"
#import "LZCameraToolkit.h"

@interface LZCameraVideoEditorViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoContainerView *videoClipView;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (strong, nonatomic) AVAsset *videoAsset;
@property (strong, nonatomic) AVAssetImageGenerator *imgGenerator;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CMTimeRange timeRange;

@end

@implementation LZCameraVideoEditorViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
	[self fetchVideoThumbnails];
}

- (void)viewWillDisappear:(BOOL)animated:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self stopTimer];
}

- (void)dealloc {
	LZCameraLog();
}

// MARK: - Public
+ (instancetype)instance {
	
	NSBundle *bundle = LZCameraNSBundle(@"");
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraVideoEditorViewController"
														 bundle:bundle];
	return storyboard.instantiateInitialViewController;
}

// MARK: - UI Action

// MAKR: - Private
- (void)setupUI {
	
	self.videoMaximumDuration = 10.0f;
	
	AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
	self.videoAsset = asset;
	self.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(self.videoAsset.duration.value, self.videoAsset.duration.timescale));
	
	self.previewImgView.image = self.previewImage;
	if (self.videoURL) {
		
		AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
		self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
		self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
		self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		self.playerLayer.frame = self.view.layer.bounds;
		[self.view.layer insertSublayer:self.playerLayer above:self.previewImgView.layer];
		[self.player play];
	}
	
	self.videoClipView.duration = self.videoAsset.duration;
	__weak typeof(self) weakSelf = self;
	self.videoClipView.TapCancelClipCallback = ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf dismissViewControllerAnimated:YES completion:nil];
	};
	
	self.videoClipView.videoMaximumDuration = self.videoMaximumDuration;
	self.videoClipView.TapPreviewClipCallback = ^(CMTimeRange timeRange) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.timeRange = timeRange;
		[strongSelf startTimer];
	};
	self.videoClipView.TapClipCallback = ^(CMTimeRange timeRange) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:strongSelf.videoAsset];
		if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
			
			AVAssetExportSession *exportSession =
			[[AVAssetExportSession alloc] initWithAsset:strongSelf.videoAsset presetName:AVAssetExportPresetMediumQuality];
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
			NSDate *date = [[NSDate alloc] init];
			NSString *outPutPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"output-%@.mp4", [formatter stringFromDate:date]]];
			NSURL *fileUrl = [NSURL fileURLWithPath:outPutPath];
			exportSession.outputURL = fileUrl;
			exportSession.shouldOptimizeForNetworkUse = true;
			exportSession.outputFileType = AVFileTypeMPEG4;
			exportSession.timeRange = timeRange;
			[exportSession exportAsynchronouslyWithCompletionHandler:^{
				if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (strongSelf.VideoClipCallback) {
							strongSelf.VideoClipCallback(fileUrl);
						}
						[strongSelf dismissViewControllerAnimated:YES completion:nil];
					});
				}
			}];
		}
	};
}

- (void)startTimer {
	
	[self stopTimer];
	CGFloat duration = self.timeRange.duration.value / self.timeRange.duration.timescale;
	self.timer =
	[NSTimer scheduledTimerWithTimeInterval:duration
									 target:self
								   selector:@selector(playPartVideo:)
								   userInfo:nil
									repeats:YES];
	[self.timer fire];
}

- (void)stopTimer {
	
	[self.timer invalidate];
	self.timer = nil;
	[self.player pause];
}

- (void)playPartVideo:(NSTimer *)timer {
	
	[self.player play];
	[self.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (CMTime)getStartTime {
	
	CMTime time = self.timeRange.start;
	if (NO == CMTIME_IS_VALID(time)) {
		time = kCMTimeZero;
	}
	return time;
}

- (void)fetchVideoThumbnails {
	
	CMTimeValue interval= 1.0f;
	__weak typeof(self) weakSelf = self;
	self.imgGenerator =
	[LZCameraToolkit thumbnailBySecondForAsset:self.videoAsset interval:interval maxSize:CGSizeMake(40, 0) completionHandler:^(AVAsset * _Nullable asset, NSArray<UIImage *> * _Nullable thumbnails) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf.videoClipView updateVideoThumbnails:thumbnails];
	}];
}

@end
