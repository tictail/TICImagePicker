//
//  TICAlbumsViewController.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TICImagePickerViewModel.h"
@import Photos;

@class TICAlbumsViewController;

@protocol TICAlbumsViewController <NSObject>

- (void)albumsViewController:(TICAlbumsViewController *)albumsViewController didSelectCollection:(PHAssetCollection *)collection;

@end


@interface TICAlbumsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) id<TICAlbumsViewController> delegate;
@property (nonatomic, strong) TICImagePickerViewModel *viewModel;
@property (nonatomic, strong) NSArray *assetCollections;

@end