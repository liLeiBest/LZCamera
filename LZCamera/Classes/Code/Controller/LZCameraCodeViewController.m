//
//  LZCameraCodeViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/29.
//

#import "LZCameraCodeViewController.h"
#import "LZCameraCodeController.h"
#import "LZCameraCodePreviewView.h"

@interface LZCameraCodeViewController ()

@property (strong, nonatomic) LZCameraCodeController *cameraCodeController;
@property (weak, nonatomic) LZCameraCodePreviewView *codePreview;

/** 保存外部传递的机器码类型 */
@property (strong, nonatomic) NSArray<AVMetadataObjectType> *machineCodeTypes;
/** 保存外部传递的过程回调 */
@property (copy, nonatomic) LZCameraDetectMachineCodeHandler detectMachineCodeHandler;

@end

@implementation LZCameraCodeViewController

// MARK: - Initialization
- (instancetype)init {
    if (self = [super init]) {
        self.machineCodeTypes = @[AVMetadataObjectTypeQRCode];
    }
    return self;
}

- (void)loadView {
    
    LZCameraCodePreviewView *codeView = [[LZCameraCodePreviewView alloc] init];
    self.view = codeView;
    self.codePreview = codeView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self setupCameraCodeController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.codePreview detectCodes:@[]];
    [self.cameraCodeController startSession];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self.cameraCodeController grantCameraAuthority]) {
        
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"请在iPhone的“设置-隐私”选项中，允许%@访问您的摄像头。", appName];
        [self alertMessage:message handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.cameraCodeController stopSession];
}

- (void)dealloc {
    LZCameraLog();
}

// MARK: - Public
+ (instancetype)instance {
    return [[LZCameraCodeViewController alloc] init];
}

- (void)detectCodeTyps:(NSArray<AVMetadataObjectType> *)codeTypes
     completionHandler:(nonnull LZCameraDetectMachineCodeHandler)completionHandler {
    
    self.machineCodeTypes = codeTypes;
    self.detectMachineCodeHandler = completionHandler;
    [self setupCameraCodeController];
}

// MARK: - Private
/**
 配置摄像头
 */
- (void)setupCameraCodeController {
    
    self.cameraCodeController = [LZCameraCodeController cameraController];
    NSError *error;
    if ([self.cameraCodeController setupSession:&error]) {
        self.codePreview.captureSesstion = self.cameraCodeController.captureSession;
    } else {
        LZCameraLog(@"CameraController config error: %@", [error localizedDescription]);
    }
    
    __weak typeof(self) weakSelf = self;
    LZCameraCaptureMetaDataCompletionHandler codeCaptureHandler =
    ^(NSArray<AVMetadataObject *> * _Nullable metadataObjects, NSError * _Nullable error) {
        
        lzPlaySound(@"code_found.wav", @"LZCameraCode");
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.codePreview detectCodes:metadataObjects];
        if (strongSelf.detectMachineCodeHandler) {
            
            NSArray *codes = [strongSelf fetchMachineCode:metadataObjects];
            strongSelf.detectMachineCodeHandler(codes, error, ^{
                [strongSelf.cameraCodeController stopSession];
            });
        }
    };
    [self.cameraCodeController captureMetaDataObjectWithTypes:self.machineCodeTypes
                                            completionHandler:codeCaptureHandler];
}

/**
 提取机器码

 @param metadataObjects @[AVMetadataObject]
 @return NSArray
 */
- (NSArray *)fetchMachineCode:(NSArray<AVMetadataObject *> *)metadataObjects {
    
    NSMutableArray *codeM = [NSMutableArray arrayWithCapacity:metadataObjects.count];
    for (AVMetadataMachineReadableCodeObject *codeObject in metadataObjects) {
        
        NSString *codeValue = codeObject.stringValue;
        if (codeValue) {
            [codeM addObject:codeObject.stringValue];
        }
    }
    return [codeM copy];
}

/**
 提示错误
 
 @param message NSString
 */
- (void)alertMessage:(NSString *)message handler:(void (^)(UIAlertAction *action))handler {
    
    UIAlertController *alertCtr =
    [UIAlertController alertControllerWithTitle:@"提示"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定"
                                                 style:UIAlertActionStyleDefault
                                               handler:handler]];
    [self presentViewController:alertCtr animated:YES completion:nil];
}

@end
