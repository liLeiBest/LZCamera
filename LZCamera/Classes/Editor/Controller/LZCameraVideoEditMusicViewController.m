//
//  LZCameraVideoEditMusicViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/25.
//

#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraEditorVideoMusicContainerView.h"
#import "LZCameraPlayer.h"
#import "LZCameraToolkit.h"
#import <LZDependencyToolkit/LZWeakTimer.h>

/** 背景音音量 */
static CGFloat BGMVolume = 1.0f;
/** 原音音量 */
static CGFloat VoiceVolume = 0.5f;
/** 监听资源导出进度的 Key */
static NSString * const AssetProgressKeyPath = @"progress";
@interface LZCameraVideoEditMusicViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoMusicContainerView *musicView;

/** 时长是否改变 */
@property (assign, nonatomic) BOOL timeRangeChange;
/** 视频播放器 */
@property (strong, nonatomic) LZCameraPlayer *videoPlayer;
/** 背景音乐播放器 */
@property (strong, nonatomic) AVAudioPlayer *BGMPlayer;
/** 背景音乐 */
@property (strong, nonatomic) LZCameraEditorMusicModel *musicModel;
/** 导出会话 */
@property (strong, nonatomic) AVAssetExportSession *exportSession;
/** 计时器 */
@property (strong, nonatomic) LZWeakTimer *timer;

@end

@implementation LZCameraVideoEditMusicViewController

// AMRK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[self stopPlay];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	self.videoPlayer.playerLayer.frame = self.previewImgView.layer.frame;
}

- (void)dealloc {
	LZCameraLog();
}

// MARK: - Public
+ (instancetype)instance {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraVideoEditMusicViewController"
														 bundle:bundle];
	return storyboard.instantiateInitialViewController;
}

// MARK: - UI Action
- (void)popDidClick {

	if (self.exportSession && (self.exportSession.status ==  AVAssetExportSessionStatusWaiting
		 || self.exportSession.status == AVAssetExportSessionStatusExporting)) {
		[self.exportSession cancelExport];
	}
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneDidClick {
	
	self.navigationItem.rightBarButtonItem.enabled = NO;
	[self stopPlay];
	[self.musicView updateEditEnable:NO];
	[self cancelExport];
	self.exportSession =
	[LZCameraToolkit mixAudioForAsset:self.videoURL
							timeRange:self.timeRange
						 audioPathURL:[self fetchBGMURL]
						originalAudio:NO
					   originalVolume:VoiceVolume
						  audioVolume:BGMVolume
						   presetName:AVAssetExportPresetMediumQuality
					completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
						
						self.navigationItem.rightBarButtonItem.enabled = YES;
						[self.timer invalidate];
						[self.musicView updateEditProgress:1.0f];
						[self.musicView updateEditEnable:YES];
						if (success) {
							if (self.VideoEditCallback) {
								self.VideoEditCallback(outputFileURL);
							}
							[[NSNotificationCenter defaultCenter] postNotificationName:LZCameraObserver_Complete object:nil];
						} else {
							[self showEditTip:@"编辑失败，请重试"];
						}
					}];
	[self scheduledTimer];
}

// MARK: - Private
- (void)setupUI {
	
	self.title = @"加音乐";
	self.tipLabel.hidden = YES;
	self.previewImgView.image = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:self.videoURL];
	[self configNavigationItem];
	[self configEditorMusicContainerView];
	[self buildPlayer];
}

- (void)configNavigationItem {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIImage *navBackImage = [UIImage imageNamed:@"nav_back_default"
									   inBundle:bundle
				  compatibleWithTraitCollection:nil];
	self.navigationItem.leftBarButtonItem =
	[[UIBarButtonItem alloc] initWithImage:navBackImage
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(popDidClick)];
	self.navigationItem.rightBarButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"完成"
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(doneDidClick)];
}

- (void)configEditorMusicContainerView {
	
	__weak typeof(self) weakSelf = self;
	self.musicView.TapOriginalMusicCallback = ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		if (strongSelf.musicModel) {
			
			[strongSelf.BGMPlayer pause];
			strongSelf.BGMPlayer = nil;
			strongSelf.musicModel = nil;
			[strongSelf startPlay];
		}
	};
	self.musicView.TapMusicCallback = ^(LZCameraEditorMusicModel * _Nonnull musicModel) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		if ([strongSelf.musicModel isEqual:musicModel]) {
			return ;
		}
		strongSelf.musicModel = musicModel;
		[strongSelf syncPlayBGMusic];
	};
	[self.musicView updateEditEnable:YES];
}

- (void)scheduledTimer {
	
	__weak typeof(self) weakSelf = self;
	self.timer =
	[LZWeakTimer scheduledTimerWithTimeInterval:1.0f
										repeats:YES
								  dispatchQueue:dispatch_get_main_queue()
								   eventHandler:^{
									 
									   typeof(weakSelf) strongSelf = weakSelf;
									   CGFloat exportProgress = strongSelf.exportSession.progress;
									   [strongSelf.musicView updateEditProgress:exportProgress];
								   }];
	[self.timer fire];
}

- (void)syncPlayBGMusic {
	
	[self stopPlay];
	[self cancelExport];
	[self.musicView updateEditEnable:NO];
	self.exportSession =
	[LZCameraToolkit cutAsset:[self fetchBGMURL]
						 type:LZCameraAssetTypeM4A
					 timeRane:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration)
			completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {

				[self.musicView updateEditEnable:YES];
				if (success) {
					
					[self.timer invalidate];
					[self.musicView updateEditProgress:1.0f];
					NSError *error;
					self.BGMPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:outputFileURL error:&error];
					if (error == nil) {

						self.BGMPlayer.numberOfLoops = -1;
						self.BGMPlayer.volume = BGMVolume;
						[self.BGMPlayer prepareToPlay];
						[self startPlay];
					}
				} else {
					[self.musicView updateEditProgress:0.0f];
				}
			}];
	[self scheduledTimer];
}

- (void)cancelExport {
	
	if (self.exportSession &&
		(self.exportSession.status ==  AVAssetExportSessionStatusWaiting ||
		 self.exportSession.status == AVAssetExportSessionStatusExporting)) {
			[self.exportSession cancelExport];
	}
}

- (NSURL *)fetchBGMURL {
	
	NSURL *musicURL = nil;
	if (self.musicModel) {
		
		NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
		NSString *musicPath = [bundle pathForResource:self.musicModel.thumbnail ofType:@"mp3"];
		musicURL = [NSURL fileURLWithPath:musicPath];
	}
	return musicURL;
}

- (void)buildPlayer {
	
	if (self.videoPlayer) {
		
		[self.videoPlayer pause];
		[self.videoPlayer.playerLayer removeFromSuperlayer];
	}
	self.videoPlayer = [LZCameraPlayer playerWithURL:self.videoURL];
	
	AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
	CMTimeRange assetTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	if (CMTIMERANGE_IS_EMPTY(self.timeRange) || CMTIMERANGE_IS_INVALID(self.timeRange)) {
		
		self.timeRange = assetTimeRange;
		self.timeRangeChange = NO;
	} else if (CMTimeRangeEqual(assetTimeRange, self.timeRange)) {
		self.timeRangeChange = NO;
	} else {
		self.timeRangeChange = YES;
	}
	self.videoPlayer.timeRange = self.timeRange;
	self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	[self.view.layer insertSublayer:self.videoPlayer.playerLayer above:self.previewImgView.layer];
	[self startPlay];
}

- (void)startPlay {
	
	[self.videoPlayer play];
	[self.BGMPlayer play];
}

- (void)stopPlay {
	
	[self.timer invalidate];
	[self.videoPlayer pause];
	[self.BGMPlayer pause];
}

- (void)showEditTip:(NSString *)tipMessage {
	
	if (!tipMessage || tipMessage.length == 0) {
		[self hideEditTip];
		return;
	}
	
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowBlurRadius = 10.0f;
	shadow.shadowOffset = CGSizeMake(0, 0);
	shadow.shadowColor = [UIColor blackColor];
	NSDictionary *attributes = @{NSShadowAttributeName : shadow};
	NSMutableAttributedString *attributedString =
	[[NSMutableAttributedString alloc] initWithString:tipMessage attributes:attributes];
	self.tipLabel.hidden = NO;
	self.tipLabel.attributedText = attributedString;
	if ([self canPerformAction:@selector(hideEditTip) withSender:nil]) {	
		[self performSelector:@selector(hideEditTip) withObject:nil afterDelay:2.0f];
	}
}

- (void)hideEditTip {
	self.tipLabel.hidden = YES;
}

@end
