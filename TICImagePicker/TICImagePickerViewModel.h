//
//  TICImagePickerViewModel.h
//  TICImagePickerExample
//
//  Created by Martin Hwasser on 13/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

@import Photos;

@interface TICImagePickerViewModel : NSObject

@property (nonatomic) BOOL shouldDisplayNumberOfAssets;
@property (nonatomic) BOOL shouldDisplayAlbumSections;

@property (nonatomic, strong) PHFetchOptions *assetsFetchOptions;

@property (nonatomic, strong) NSArray *assetCollectionSubtypes;

@end
