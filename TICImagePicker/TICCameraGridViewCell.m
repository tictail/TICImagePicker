//
//  TICCameraGridViewCell.m
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "TICCameraGridViewCell.h"
#import "NSBundle+Tictail.h"

@interface TICCameraGridViewCell ()

@property (nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation TICCameraGridViewCell

+ (NSString *)mediaType {
  return AVMediaTypeVideo;
}

+ (AVAuthorizationStatus)authorizationStatus {
  return [AVCaptureDevice authorizationStatusForMediaType:[self mediaType]];
}

+ (AVCaptureDevice *)captureDevice {
  static AVCaptureDevice *captureDevice = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:[self mediaType]];
  });
  return captureDevice;
}

+ (BOOL)isCameraAvailable {
  return nil != [self captureDevice];
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self.contentView setBackgroundColor:[UIColor blackColor]];
    [self.contentView addSubview:self.cameraImageView];
    self.cameraType = AVCaptureDevicePositionBack;
    
    [self setupSession];
  }
  return self;
}

- (void)setupSession {
  self.session = [[AVCaptureSession alloc] init];
  self.session.sessionPreset = AVCaptureSessionPreset352x288;
  
  self.sessionQueue = dispatch_queue_create("com.tictail.sessionQueue", DISPATCH_QUEUE_SERIAL);
  NSError *error = nil;
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:[self.class captureDevice] error:&error];
  if (!input) {
    // Handle the error appropriately.
    NSLog(@"ERROR: trying to open camera: %@", error);
  } else {
    if ([self.session canAddInput:input]) {
      [self.session addInput:input];
      
      AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
      captureVideoPreviewLayer.frame = self.bounds;
      captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
      [self.contentView.layer addSublayer:captureVideoPreviewLayer];
    } else {
      NSLog(@"Couldn't add camera input");
    }
  }
}

- (UIImageView *)cameraImageView {
  if (!_cameraImageView) {
    UIImage *image = [UIImage imageNamed:@"TICCameraIcon"
                                inBundle:[NSBundle tic_bundleForClass:self.class]
           compatibleWithTraitCollection:nil];
    _cameraImageView = [[UIImageView alloc] initWithImage:image];
    _cameraImageView.contentMode = UIViewContentModeCenter;
  }
  return _cameraImageView;
}

- (void)startCamera {
  dispatch_async(self.sessionQueue, ^{
    if (!self.session.isRunning) {
      [self.session startRunning];
    }
  });
}

- (void)stopCamera {
  dispatch_async(self.sessionQueue, ^{
    if (_session.isRunning) {
      [_session stopRunning];
    };
  });
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect frame = self.bounds;
  self.cameraImageView.frame = frame;
  [self.cameraImageView.superview bringSubviewToFront:self.cameraImageView];
}

@end
