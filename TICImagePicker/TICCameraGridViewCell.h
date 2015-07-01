//
//  TICCameraGridViewCell.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TICCameraGridViewCell : UICollectionViewCell

@property (nonatomic) AVCaptureDevicePosition cameraType;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) UIImageView *cameraImageView;

- (void)startCamera:(void (^)())completion;
- (void)stopCamera:(void (^)())completion;

+ (AVAuthorizationStatus)authorizationStatus;
+ (BOOL)isCameraAvailable;
+ (NSString *)mediaType;

@end
