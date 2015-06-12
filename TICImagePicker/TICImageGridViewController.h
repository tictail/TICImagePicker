//
//  TICImageGridViewController.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//


#import "TICImagePickerController.h"

@import UIKit;
@import Photos;


@interface TICImageGridViewController : UICollectionViewController

@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, strong) PHFetchResult *assetsFetchResults;

- (id)initWithPicker:(TICImagePickerController *)picker;

@end