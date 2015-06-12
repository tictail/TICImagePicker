//
//  TICAlbumsViewController.m
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "TICImagePickerController.h"
#import "TICAlbumsViewController.h"
#import "TICAlbumCell.h"

@interface TICAlbumsViewController() <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHImageManager *imageManager;

@end

@implementation TICAlbumsViewController

- (void)dealloc {
  [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.tableView registerClass:[TICAlbumCell class] forCellReuseIdentifier:NSStringFromClass(TICAlbumCell.class)];
  [self.view addSubview:self.tableView];
  [self reloadData];
  
  [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}


#pragma mark -
#pragma mark - Properties

- (NSArray *)collectionsFetchResults {
  if (!_collectionsFetchResults) {
    PHFetchResult *smartUserLibraryAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                                     subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                                     options:nil];
    PHFetchResult *smartRegularAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                                 subtype:PHAssetCollectionSubtypeAlbumRegular
                                                                                 options:nil];
    self.collectionsFetchResults = @[smartUserLibraryAlbums, smartRegularAlbums];
  }
  return _collectionsFetchResults;
}

- (PHImageManager *)imageManager {
  if (!_imageManager) {
    _imageManager = [PHImageManager new];
  }
  return _imageManager;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    _tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    _tableView.rowHeight = MHWAlbumCellImageRadius + 8 * 2;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _tableView.separatorEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    _tableView.separatorInset = UIEdgeInsetsZero;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [_tableView registerClass:TICAlbumCell.class forCellReuseIdentifier:NSStringFromClass(TICAlbumCell.class)];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  }
  return _tableView;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.collectionsFetchResults.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger numberOfRows = 0;
  PHFetchResult *fetchResult = self.collectionsFetchResults[section];
  numberOfRows = fetchResult.count;
  return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  TICAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(TICAlbumCell.class) forIndexPath:indexPath];

  NSInteger currentTag = cell.tag + 1;
  cell.tag = currentTag;
  
  PHFetchResult *assetsFetchResult = nil;
  NSString *localizedTitle = nil;
  
  PHFetchResult *fetchResult = self.collectionsFetchResults[indexPath.section];
  PHAssetCollection *assetCollection = fetchResult[indexPath.row];
  localizedTitle = assetCollection.localizedTitle;
  cell.titleLabel.text = localizedTitle;

  assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.assetsFetchOptions];
  
  if (self.shouldDisplayNumberOfAssets) {
    cell.countLabel.text = [NSString stringWithFormat:@"%@", @(assetsFetchResult.count)];
  }

  PHAsset *asset = assetsFetchResult.firstObject;
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize targetSize = CGSizeMake(MHWAlbumCellImageRadius * scale, MHWAlbumCellImageRadius * scale);
  
  [self.imageManager requestImageForAsset:asset
                               targetSize:targetSize
                              contentMode:PHImageContentModeAspectFill
                                  options:nil
                            resultHandler:^(UIImage *result, NSDictionary *info) {
                              if (cell.tag == currentTag) {
                                cell.imageView.image = result;
                              }
   }];
  return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  NSString *title = nil;
  if (self.shouldDisplayAlbumSections) {
    PHFetchResult *fetchResult = self.collectionsFetchResults[section];
    PHAssetCollection *assetCollection = fetchResult.firstObject;
    title = assetCollection.localizedTitle;
  }
  return title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  PHFetchResult *fetchResult = self.collectionsFetchResults[indexPath.section];
  PHAssetCollection *assetCollection = fetchResult[indexPath.row];
  [self.delegate albumsViewController:self didSelectCollection:assetCollection];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)reloadData {
  [self.tableView reloadData];
  self.preferredContentSize = self.tableView.contentSize;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
  // Call might come on any background queue. Re-dispatch to the main queue to handle it.
  dispatch_async(dispatch_get_main_queue(), ^{
    
    NSMutableArray *updatedCollectionsFetchResults = nil;
    
    for (PHFetchResult *collectionsFetchResult in self.collectionsFetchResults) {
      PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
      if (changeDetails) {
        if (!updatedCollectionsFetchResults) {
          updatedCollectionsFetchResults = [self.collectionsFetchResults mutableCopy];
        }
        [updatedCollectionsFetchResults replaceObjectAtIndex:[self.collectionsFetchResults indexOfObject:collectionsFetchResult] withObject:[changeDetails fetchResultAfterChanges]];
      }
    }
    
    if (updatedCollectionsFetchResults) {
      self.collectionsFetchResults = updatedCollectionsFetchResults;
      [self reloadData];
    }
    
  });
}

@end