//
//  LZCameraPlayer.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/27.
//

#import "LZCameraPlayer.h"

@interface LZCameraPlayer()

/** 播放器视图 */
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
/** 计时器 */
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation LZCameraPlayer

// MARK: - Initialization
- (instancetype)init {
	if (self = [super init]) {
		[self registerObserver];
		[self setupUI];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - Public
- (void)setVideoURL:(NSURL *)videoURL {
	_videoURL = videoURL;
	
	[self buildPlayer];
}

+ (instancetype)playerWithURL:(NSURL *)URL {
	
	LZCameraPlayer *player = [[LZCameraPlayer alloc] init];
	player.videoURL = URL;
	return player;
}

- (void)play {
	
	[self pause];
	CGFloat duration = CMTimeGetSeconds(self.timeRange.duration);
	self.timer =
	[NSTimer scheduledTimerWithTimeInterval:duration
									 target:self
								   selector:@selector(playerItemDidPlayToEnd:)
								   userInfo:nil
									repeats:YES];
	[self.timer fire];
}

- (void)pause {
	
	[self.timer invalidate];
	self.timer = nil;
	[self.playerLayer.player pause];
}

- (void)setVolume:(CGFloat)volume {
	_volume = volume;
	
	self.playerLayer.player.volume = volume;
}

// AMRK: - Private
- (void)setupUI {
	
	self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
}

- (void)registerObserver {
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(appWillResignActive)
	 name:UIApplicationWillResignActiveNotification
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(appDidBecomeActive)
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
}

- (CMTime)fetchPlayStartTime {
	
	CMTime time = self.timeRange.start;
	if (NO == CMTIME_IS_VALID(time)) {
		time = kCMTimeZero;
	}
	return time;
}

- (void)buildPlayer {
	
	AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
	if (NO == CMTIMERANGE_IS_VALID(self.timeRange)) {
		self.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	}
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
	self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	self.playerLayer.videoGravity = AVLayerVideoGravityResize;
}

// MARK: - Observer
- (void)playerItemDidPlayToEnd:(NSTimer *)timer {
	
	[self.playerLayer.player play];
	[self.playerLayer.player seekToTime:[self fetchPlayStartTime]
						toleranceBefore:kCMTimeZero
						 toleranceAfter:kCMTimeZero];
	if (self.playToEndCallback) {
		self.playToEndCallback();
	}
}

- (void)appWillResignActive {
	[self.playerLayer.player pause];
}

- (void)appDidBecomeActive {
	[self.playerLayer.player play];
}

@end
