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
@property (nonatomic, strong) NSArray *collectionsFetchResults;
@property (nonatomic, strong) NSArray *assetsFetchResults;

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
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                          subtype:PHAssetCollectionSubtypeAny
                                                                          options:nil];
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                         subtype:PHAssetCollectionSubtypeAny
                                                                         options:nil];
    self.collectionsFetchResults = @[smartAlbums, userAlbums];
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
    _tableView.rowHeight = TICAlbumCellImageDiameter + 10 * 2;
    _tableView.separatorInset = UIEdgeInsetsZero;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [_tableView registerClass:TICAlbumCell.class forCellReuseIdentifier:NSStringFromClass(TICAlbumCell.class)];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  }
  return _tableView;
}


#pragma mark -
#pragma mark - Methods

- (NSArray *)assetCollections {
  if (!_assetCollections) {
    NSMutableArray *assetCollections = [NSMutableArray array];

    // Filter albums
    NSArray *assetCollectionSubtypes = self.viewModel.assetCollectionSubtypes;
    NSMutableDictionary *smartAlbums = [NSMutableDictionary dictionaryWithCapacity:assetCollectionSubtypes.count];
    NSMutableArray *userAlbums = [NSMutableArray array];

    for (PHFetchResult *fetchResult in self.collectionsFetchResults) {
      [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger index, BOOL *stop) {
        if (assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeAlbumRegular) {
          [userAlbums addObject:assetCollection];
        } else if ([assetCollectionSubtypes containsObject:@(assetCollection.assetCollectionSubtype)]) {
          smartAlbums[@(assetCollection.assetCollectionSubtype)] = assetCollection;
        }
      }];
    }

    // Fetch smart albums
    for (NSNumber *assetCollectionSubtype in assetCollectionSubtypes) {
      PHAssetCollection *assetCollection = smartAlbums[assetCollectionSubtype];
      if (assetCollection) {
        [assetCollections addObject:assetCollection];
      }
    }

    // Fetch user albums
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger index, BOOL *stop) {
      [assetCollections addObject:assetCollection];
    }];
    
    NSMutableArray *assetsFetchResults = [@[] mutableCopy];
    [assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger idx, BOOL *stop) {
      PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.viewModel.assetsFetchOptions];
      [assetsFetchResults addObject:assetsFetchResult];
    }];
    
    self.assetsFetchResults = [assetsFetchResults copy];

    _assetCollections = [assetCollections copy];
  }
  return _assetCollections;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.assetCollections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  TICAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(TICAlbumCell.class) forIndexPath:indexPath];

  NSInteger currentTag = cell.tag + 1;
  cell.tag = currentTag;
  
  PHFetchResult *assetsFetchResult = nil;
  NSString *localizedTitle = nil;

  PHAssetCollection *assetCollection = self.assetCollections[indexPath.item];
  localizedTitle = assetCollection.localizedTitle;
  cell.titleLabel.text = localizedTitle;

  assetsFetchResult = self.assetsFetchResults[indexPath.item];
  
  if (self.viewModel.shouldDisplayNumberOfAssets) {
    cell.countLabel.text = [NSString stringWithFormat:@"%@", @(assetsFetchResult.count)];
  }

  PHAsset *asset = assetsFetchResult.firstObject;
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize targetSize = CGSizeMake(TICAlbumCellImageDiameter * scale, TICAlbumCellImageDiameter * scale);
  
  [self.imageManager requestImageForAsset:asset
                               targetSize:targetSize
                              contentMode:PHImageContentModeAspectFill
                                  options:nil
                            resultHandler:^(UIImage *result, NSDictionary *info) {
                              if (cell.tag == currentTag) {
                                cell.thumbnailImageView.image = result;
                              }
   }];
  return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  NSString *title = nil;
  if (self.viewModel.shouldDisplayAlbumSections) {
    PHFetchResult *fetchResult = self.collectionsFetchResults[section];
    PHAssetCollection *assetCollection = fetchResult.firstObject;
    title = assetCollection.localizedTitle;
  }
  return title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  PHAssetCollection *assetCollection = self.assetCollections[indexPath.row];
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
      self.assetCollections = nil;
      [self reloadData];
    }
    
  });
}

@end