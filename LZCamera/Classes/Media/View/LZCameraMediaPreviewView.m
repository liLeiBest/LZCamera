//
//  LZCameraMediaPreviewView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/19.
//

#import "LZCameraMediaPreviewView.h"

@interface LZCameraMediaPreviewView()

/** 聚集框 */
@property (strong, nonatomic) UIView *focusBoxView;
/** 曝光框 */
@property (strong, nonatomic) UIView *exposureBoxView;
/** 单指单击 */
@property (strong, nonatomic) UITapGestureRecognizer *singleTapSingleGestureRecognizer;
/** 单指双击*/
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapSingleGestureRecognizer;
/** 双指双击 */
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapDoubleGestureRecognizer;
/** 双指捏合 */
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchTapDoubleGestureRecognizer;

@property (strong, nonatomic) CALayer *overLayer;
@property (strong, nonatomic) NSMutableDictionary *faceLayers;

@end

@implementation LZCameraMediaPreviewView

// MARK: - Initialization
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self setupView];
    }
    return self;
}

- (void)setSingleTapToFocusEnable:(BOOL)singleTapToFocusEnable {
    _singleTapToFocusEnable = singleTapToFocusEnable;
    
    self.singleTapSingleGestureRecognizer.enabled = singleTapToFocusEnable;
}

- (void)setDoubleTapToExposeEnable:(BOOL)doubleTapToExposeEnable {
    _doubleTapToExposeEnable = doubleTapToExposeEnable;
    
    self.doubleTapSingleGestureRecognizer.enabled = doubleTapToExposeEnable;
}

// MARK: - Public
- (void)detectFaces:(NSArray<AVMetadataObject *> *)faces {
    
    NSArray *transformFaces = @[];
    if (faces && faces.count) {
        transformFaces = [self transformedFacesFromFaces:faces];
    }
    
    NSMutableArray *lostFaces = [self.faceLayers.allKeys mutableCopy];
    for (AVMetadataFaceObject *face in transformFaces) {
        
        NSNumber *faceID = @(face.faceID);
        [lostFaces removeObject:faceID];
        
        CALayer *layer = [self.faceLayers objectForKey:faceID];
        if (!layer) {
            
            layer = [self makeFaceLayer];
            [self.overLayer addSublayer:layer];
            self.faceLayers[faceID] = layer;
        }
        
        layer.transform = CATransform3DIdentity;
        layer.frame = face.bounds;
        
#if 0
        /**
         根据角度旋转
         */
        if (face.hasRollAngle) {

            CATransform3D transform = [self transformForRollAngle:face.rollAngle];
            layer.transform = CATransform3DConcat(layer.transform, transform);
        }
        if (face.hasYawAngle) {

            CATransform3D transform = [self transformForYawAngle:face.yawAngle];
            layer.transform = CATransform3DConcat(layer.transform, transform);
        }
#endif
    }
    
    for (NSNumber *faceID in lostFaces) {
        
        CALayer *layer = [self.faceLayers objectForKey:faceID];
        [layer removeFromSuperlayer];
        [self.faceLayers removeObjectForKey:faceID];
    }
}

// MARK: - UI Action
- (void)handleSingleTapForSingleGesture:(UIGestureRecognizer *)recognizer {
    
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.focusBoxView point:point];
    if (self.TapToFocusAtPointHandler) {
        self.TapToFocusAtPointHandler([self changePointOfSelfTappedForCameraPoint:point]);
    }
}

- (void)handleDoubleTapForSingleGeture:(UIGestureRecognizer *)recognizer {
    
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.exposureBoxView point:point];
    if (self.TapToExposeAtPointHandler) {
        self.TapToExposeAtPointHandler([self changePointOfSelfTappedForCameraPoint:point]);
    }
}

- (void)handleDoubleTapForDoubleGeture:(UIGestureRecognizer *)recognizer {
    
    [self runResetAnimation];
    if (self.TapToResetFocusAndExposure) {
        self.TapToResetFocusAndExposure();
    }
}

- (void)handlePinchTapForDoubleGesture:(UIPinchGestureRecognizer *)recognizer {
    
    LZCameraLog(@"Pinch tap scale:%f velocity:%f", recognizer.scale, recognizer.velocity);
    if (self.PinchToZoomHandler) {
        self.PinchToZoomHandler(recognizer.state == UIGestureRecognizerStateEnded, recognizer.velocity >= 0, 1.0f);
    }
}

// MARK: - Private
/**
 设置视图
 */
- (void)setupView {
    
    self.singleTapSingleGestureRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTapForSingleGesture:)];
    self.singleTapSingleGestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:self.singleTapSingleGestureRecognizer];
    
    self.doubleTapSingleGestureRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleDoubleTapForSingleGeture:)];
    self.doubleTapSingleGestureRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:self.doubleTapSingleGestureRecognizer];
    [self.singleTapSingleGestureRecognizer requireGestureRecognizerToFail:self.doubleTapSingleGestureRecognizer];
    
    self.doubleTapDoubleGestureRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleDoubleTapForDoubleGeture:)];
    self.doubleTapDoubleGestureRecognizer.numberOfTapsRequired = 2;
    self.doubleTapDoubleGestureRecognizer.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:self.doubleTapDoubleGestureRecognizer];
    
    self.pinchTapDoubleGestureRecognizer =
    [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handlePinchTapForDoubleGesture:)];
    [self addGestureRecognizer:self.pinchTapDoubleGestureRecognizer];
    
    self.focusBoxView = [self boxViewWithColor:[UIColor colorWithRed:254.0f/255.0f green:195.0f/255.0f blue:9.0f/255.0f alpha:1.0f]];
    [self addSubview:self.focusBoxView];
    
    self.exposureBoxView = [self boxViewWithColor:[UIColor colorWithRed:1.000 green:0.421 blue:0.054 alpha:1.000]];
    [self addSubview:self.exposureBoxView];
    
    self.faceLayers = [NSMutableDictionary dictionary];
    self.overLayer = [CALayer layer];
	self.overLayer.frame = self.previewLayer.bounds;
    self.overLayer.sublayerTransform = CATransform3DMakePerspective(1000);
    [self.previewLayer addSublayer:self.overLayer];
}

/**
 生成提示框

 @param color UIColor
 @return UIView
 */
- (UIView *)boxViewWithColor:(UIColor *)color {
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 120.0f)];
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 3.0f;
    view.hidden = YES;
    return view;
}

/**
 执行相应提示框动画

 @param view UIView
 @param point CGPoint
 */
- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
    
    view.center = point;
    view.hidden = NO;
    [UIView animateWithDuration:0.15
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(0.5f, 0.5f, 1.0f);
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            view.hidden = YES;
            view.transform = CGAffineTransformIdentity;
        });
    }];
}

/**
 执行重置动画
 */
- (void)runResetAnimation {
    
    if (!self.singleTapToFocusEnable && !self.doubleTapToExposeEnable) {
        return;
    }
    
    AVCaptureVideoPreviewLayer *previewlayer = self.previewLayer;
    CGPoint centerPoint = [previewlayer pointForCaptureDevicePointOfInterest:CGPointMake(0.5f, 0.5f)];
    self.focusBoxView.center = centerPoint;
    self.exposureBoxView.center = centerPoint;
    self.exposureBoxView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
    self.focusBoxView.hidden = NO;
    self.exposureBoxView.hidden = NO;
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        
                         self.focusBoxView.layer.transform = CATransform3DMakeScale(0.5f, 0.5f, 1.0f);
                         self.exposureBoxView.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0);
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            self.focusBoxView.hidden = YES;
            self.exposureBoxView.hidden = YES;
            self.focusBoxView.layer.transform = CATransform3DIdentity;
            self.exposureBoxView.layer.transform = CATransform3DIdentity;
        });
    }];
}

/**
 将视图的点坐标转换为摄像机的点坐标

 @param point CGPoint
 @return CGPoint
 */
- (CGPoint)changePointOfSelfTappedForCameraPoint:(CGPoint)point {
    
    AVCaptureVideoPreviewLayer *previewLayer = self.previewLayer;
    return [previewLayer captureDevicePointOfInterestForPoint:point];
}

- (NSArray *)transformedFacesFromFaces:(NSArray *)faces {
    
    NSMutableArray *transformedFaces = [NSMutableArray array];
    for (AVMetadataObject *face in faces) {
        
        AVMetadataObject *transformedFace = [self.previewLayer transformedMetadataObjectForMetadataObject:face];
        if (transformedFace) {
            [transformedFaces addObject:transformedFace];
        }
    }
    
    return [transformedFaces copy];
}

/**
 创建人脸提示框

 @return CALayer
 */
- (CALayer *)makeFaceLayer {
    
    CALayer *layer = [CALayer layer];
    layer.borderWidth = 2.0f;
    layer.borderColor =
    [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f].CGColor;
    return layer;
}

/**
 Z 轴旋转（转头）

 @param rollAngleInDegress CGFloat
 @return CATransform3D
 */
- (CATransform3D)transformForRollAngle:(CGFloat)rollAngleInDegress {
    
    CGFloat rollAngleInRadians = LZDegreesToRadians(rollAngleInDegress);
    return CATransform3DMakeRotation(rollAngleInRadians, 0.0f, 0.0f, 1.0f);
}

- (CATransform3D)orientationTransform {
    
    CGFloat angle = 0.0f;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI / 2.0f;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI / 2.0f;
            break;
        default:
            angle = 0.0f;
            break;
    }
    return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

/**
 Y 轴倾斜（歪脑袋）

 @param yawAngleInDegrees CGFloat
 @return CATransform3D
 */
- (CATransform3D)transformForYawAngle:(CGFloat)yawAngleInDegrees {
    
    CGFloat yawAngleInRadians = LZDegreesToRadians(yawAngleInDegrees);
    CATransform3D yawTransform = CATransform3DMakeRotation(yawAngleInRadians, 0.0f, -1.0f, 0.0f);
    return CATransform3DConcat(yawTransform, [self orientationTransform]);
}

/**
 角度转弧角

 @param degrees CGFloat
 @return CGFloat
 */
static CGFloat LZDegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180.0f;
}

static CATransform3D CATransform3DMakePerspective(CGFloat eyePosition) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / eyePosition;
    return transform;
}

@end
