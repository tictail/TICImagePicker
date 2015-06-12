//
//  TICAlbumsViewController.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;

@class TICAlbumsViewController;

@protocol MHWAlbumsViewController <NSObject>

- (void)albumsViewController:(TICAlbumsViewController *)albumsViewController didSelectCollection:(PHAssetCollection *)collection;

@end


@interface TICAlbumsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) id<MHWAlbumsViewController> delegate;
@property (nonatomic, strong) NSArray *collectionsFetchResults;

@property (nonatomic) BOOL shouldDisplayNumberOfAssets;
@property (nonatomic) BOOL shouldDisplayAlbumSections;

@property (nonatomic, strong) PHFetchOptions *assetsFetchOptions;

@end