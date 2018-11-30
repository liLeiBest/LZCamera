//
//  LZCameraCodeScanView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/30.
//

#import "LZCameraCodeScanView.h"

@interface LZCameraCodeScanView()

@property (weak, nonatomic) UIImageView *leftTop;
@property (weak, nonatomic) UIImageView *leftBottom;
@property (weak, nonatomic) UIImageView *rightTop;
@property (weak, nonatomic) UIImageView *rightBottom;

@end
@implementation LZCameraCodeScanView

// MARK: - Initialization
- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = CGSizeMake(30, 30);
    self.leftTop.frame = (CGRect){0,0,size};
    self.leftBottom.frame = (CGRect){0,self.frame.size.height - size.height,size};
    self.rightTop.frame = (CGRect){self.frame.size.width - size.width,0,size};
    self.rightBottom.frame = (CGRect){self.frame.size.width - size.width,self.frame.size.height - size.height,size};
}

// MARK: - Private
- (void)setupView {
    
    
    UIImageView *leftTop = [[UIImageView alloc] init];
    leftTop.image = [self imageInBundle:@"code_scan_left_top"];
    [self addSubview:leftTop];
    self.leftTop = leftTop;
    
    UIImageView *leftBottom = [[UIImageView alloc] init];
    leftBottom.image = [self imageInBundle:@"code_scan_left_bottom"];
    [self addSubview:leftBottom];
    self.leftBottom = leftBottom;
    
    UIImageView *rightTop = [[UIImageView alloc] init];
    rightTop.image = [self imageInBundle:@"code_scan_right_top"];
    [self addSubview:rightTop];
    self.rightTop = rightTop;
    
    UIImageView *rightBottom = [[UIImageView alloc] init];
    rightBottom.image = [self imageInBundle:@"code_scan_right_bottom"];
    [self addSubview:rightBottom];
    self.rightBottom = rightBottom;
}

/**
 加载图片资源
 
 @param imageName NSString
 @return UIImage
 */
- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraCode");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

@end
