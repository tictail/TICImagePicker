//
//  TICImageGridViewController.m
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "TICImageGridViewController.h"
#import "TICImagePickerController.h"
#import "TICAlbumsViewController.h"
#import "TICImageGridViewCell.h"
#import "TICCameraGridViewCell.h"
#import <MobileCoreServices/MobileCoreServices.h>

@import Photos;

//Helper methods
@implementation NSIndexSet (Convenience)

- (NSArray *)aapl_indexPathsFromIndexesWithSection:(NSUInteger)section itemOffset:(NSUInteger)offset {
  NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
  [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    [indexPaths addObject:[NSIndexPath indexPathForItem:idx + offset inSection:section]];
  }];
  return indexPaths;
}

@end

@implementation UICollectionView (Convenience)

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
  NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
  if (allLayoutAttributes.count == 0) { return nil; }
  NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
  for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
    NSIndexPath *indexPath = layoutAttributes.indexPath;
    [indexPaths addObject:indexPath];
  }
  return indexPaths;
}

@end


@interface TICImageGridViewController ()
<
UICollectionViewDelegateFlowLayout,
PHPhotoLibraryChangeObserver,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UIAlertViewDelegate
>

@property (nonatomic, weak) TICImagePickerController *picker;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;

@end

static CGSize AssetGridThumbnailSize;

@implementation TICImageGridViewController

- (void)dealloc {
  [self resetCachedAssets];
  [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (id)initWithPicker:(TICImagePickerController *)picker {
  if (self = [super initWithCollectionViewLayout:[UICollectionViewFlowLayout new]]) {
    
    self.picker = picker;

    self.collectionView.allowsMultipleSelection = picker.allowsMultipleSelection;
    self.collectionView.backgroundColor = [UIColor whiteColor];

    [self.collectionView registerClass:[TICImageGridViewCell class]
            forCellWithReuseIdentifier:NSStringFromClass([TICImageGridViewCell class])];
    [self.collectionView registerClass:[TICCameraGridViewCell class]
            forCellWithReuseIdentifier:NSStringFromClass([TICCameraGridViewCell class])];
  }
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self resetCachedAssets];
  [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [self updateCachedAssets];
  [self startCameraIfNeeded];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  // Save indexPath for the last item
  NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] lastObject];

  // Update layout
  [self.collectionViewLayout invalidateLayout];

  // Restore scroll position
  [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
  }];
}


#pragma mark - 
#pragma mark - Image Manager

- (PHCachingImageManager *)imageManager {
  if (!_imageManager) {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == AVAuthorizationStatusAuthorized) {
      _imageManager = [PHCachingImageManager new];
      [self.collectionView reloadData];
    }
  }
  return _imageManager;
}


#pragma mark -
#pragma mark - Camera

- (BOOL)shouldShowCameraCell {
  return [TICCameraGridViewCell isCameraAvailable] && self.assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
}

- (TICCameraGridViewCell *)cameraGridViewCell {
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  return (TICCameraGridViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}

- (void)startCameraIfNeeded {
  if ([self shouldShowCameraCell]) {
    AVAuthorizationStatus status = [TICCameraGridViewCell authorizationStatus];
    if (status == AVAuthorizationStatusNotDetermined) {
      [AVCaptureDevice requestAccessForMediaType:[TICCameraGridViewCell mediaType] completionHandler:^(BOOL granted) {
        if (granted) {
          [[self cameraGridViewCell] startCamera:nil];
        }
      }];
    } else if (status == AVAuthorizationStatusAuthorized) {
      [[self cameraGridViewCell] startCamera:nil];
    }
  }
}

- (void)presentCameraViewController {
  if ([TICCameraGridViewCell authorizationStatus] == AVAuthorizationStatusAuthorized) {
    [[self cameraGridViewCell] stopCamera:^{
      UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
      UIImagePickerController *cameraController = [UIImagePickerController new];
      cameraController.sourceType = sourceType;
      cameraController.delegate = self;
      cameraController.mediaTypes = @[(NSString *)kUTTypeImage];
      [self presentViewController:cameraController animated:YES completion:nil];
    }];
    } else {
      [self presentCameraAuthorizationError];
    }
}


#pragma mark -
#pragma mark - Collection View

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item == 0 && [self shouldShowCameraCell]) {
    TICCameraGridViewCell *cameraPreviewCell =
    [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TICCameraGridViewCell class])
                                              forIndexPath:indexPath];
    return cameraPreviewCell;
  } else {
    TICImageGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TICImageGridViewCell class])
                                                                           forIndexPath:indexPath];
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    [self.imageManager requestImageForAsset:asset
                                 targetSize:AssetGridThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                                if (cell.tag == currentTag) {
                                  [cell.imageView setImage:result];
                                }
                              }];
    
    // Setting `selected` property blocks further deselection. Have to call selectItemAtIndexPath too. ( ref: http://stackoverflow.com/a/17812116/1648333 )
    if ([self.picker.selectedAssets containsObject:asset]) {
      cell.selected = YES;
      [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
      cell.selected = NO;
    }
    
    return cell;
  }
}


#pragma mark - Collection View Delegate

- (BOOL)isAssetIndexPath:(NSIndexPath *)indexPath {
  return 0 < indexPath.item || ![self shouldShowCameraCell];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isAssetIndexPath:indexPath]) {
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(imagePickerController:shouldSelectAsset:)]) {
      return [self.picker.delegate imagePickerController:self.picker shouldSelectAsset:asset];
    }
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isAssetIndexPath:indexPath]) {
    // Could already be selected if allowsMultipleSelection = NO
    if ([self.picker.selectedAssets containsObject:[self assetAtIndexPath:indexPath]]) {
      [self deselectAssetAtIndexPath:indexPath];
    } else {
      [self selectAssetAtIndexPath:indexPath];
    }
  } else {
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    if ([self.picker.delegate respondsToSelector:@selector(imagePickerController:didTapCameraCell:)]) {
      TICCameraGridViewCell *cell = (TICCameraGridViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
      [self.picker.delegate imagePickerController:self.picker didTapCameraCell:cell];
    }
    if (!self.picker.shouldUseCustomCameraController) {
      [self presentCameraViewController];
    }
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isAssetIndexPath:indexPath]) {
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    if ([self.picker.delegate respondsToSelector:@selector(imagePickerController:shouldDeselectAsset:)]) {
      return [self.picker.delegate imagePickerController:self.picker shouldDeselectAsset:asset];
    }
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isAssetIndexPath:indexPath]) {
    [self deselectAssetAtIndexPath:indexPath];
  }
}


- (void)selectAssetAtIndexPath:(NSIndexPath *)indexPath {
  PHAsset *asset = [self assetAtIndexPath:indexPath];
  [self.picker selectAsset:asset];
  [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
  
  if ([self.picker.delegate respondsToSelector:@selector(imagePickerController:didSelectAsset:)]) {
    [self.picker.delegate imagePickerController:self.picker didSelectAsset:asset];
  }
}

- (void)deselectAssetAtIndexPath:(NSIndexPath *)indexPath {
  PHAsset *asset = [self assetAtIndexPath:indexPath];
  [self.picker deselectAsset:asset];
  if ([self.picker.delegate respondsToSelector:@selector(imagePickerController:didDeselectAsset:)]) {
    [self.picker.delegate imagePickerController:self.picker didDeselectAsset:asset];
  }
  [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}


#pragma mark - willDisplayCell:/didEndDisplayingCell:

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([cell isKindOfClass:[TICCameraGridViewCell class]]) {
    [(TICCameraGridViewCell *)cell startCamera:nil];
  }
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([cell isKindOfClass:[TICCameraGridViewCell class]]) {
    [(TICCameraGridViewCell *)cell stopCamera:nil];
  }
}


#pragma mark - UICollectionViewDataSource

- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath {
  NSUInteger index = indexPath.item - ([self shouldShowCameraCell] ? 1 : 0);
  PHAsset *asset = self.assetsFetchResults[index];
  return asset;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (!self.imageManager) return 0;
  NSInteger count = self.assetsFetchResults.count;
  if ([self shouldShowCameraCell]) {
    count++;
  }
  return count;
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
  // Call might come on any background queue. Re-dispatch to the main queue to handle it.
  dispatch_async(dispatch_get_main_queue(), ^{
    
    // check if there are changes to the assets (insertions, deletions, updates)
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
    if (collectionChanges) {
      
      // get the new fetch result
      self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
      
      UICollectionView *collectionView = self.collectionView;
      
      if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
        // we need to reload all if the incremental diffs are not available
        [collectionView reloadData];
      } else {
        // if we have incremental diffs, tell the collection view to animate insertions and deletions
        NSUInteger itemOffset = [self shouldShowCameraCell] ? 1 : 0;
        
        NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
        NSArray *removedPaths = [removedIndexes aapl_indexPathsFromIndexesWithSection:0 itemOffset:itemOffset];
        
        NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
        NSArray *insertedPaths = [insertedIndexes aapl_indexPathsFromIndexesWithSection:0 itemOffset:itemOffset];
        
        NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
        NSArray *changedPaths = [changedIndexes aapl_indexPathsFromIndexesWithSection:0 itemOffset:itemOffset];
        
        BOOL shouldReload = NO;
        
        if (changedPaths.count && removedPaths.count) {
          for (NSIndexPath *changedPath in changedPaths) {
            if ([removedPaths containsObject:changedPath]) {
              shouldReload = YES;
              break;
            }
          }
        }
        
        NSIndexPath *lastRemovedIndexPath = (NSIndexPath *)removedPaths.lastObject;
        if (lastRemovedIndexPath.item >= self.assetsFetchResults.count) {
          shouldReload = YES;
        }
        
        if (shouldReload) {
          [collectionView reloadData];
        } else {
          [collectionView performBatchUpdates:^{
            if ([removedPaths count]) {
              [collectionView deleteItemsAtIndexPaths:removedPaths];
            }
            if ([insertedPaths count]) {
              [collectionView insertItemsAtIndexPaths:insertedPaths];
            }
            if ([changedPaths count]) {
              [collectionView reloadItemsAtIndexPaths:changedPaths];
            }
          } completion:NULL];
        }
      }
      
      [self resetCachedAssets];
    }
  });
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self updateCachedAssets];
}


#pragma mark - Asset Caching

- (void)resetCachedAssets {
  [self.imageManager stopCachingImagesForAllAssets];
  self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
  BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
  if (!isViewVisible) return;
  
  // The preheat window is twice the height of the visible rect
  CGRect preheatRect = self.collectionView.bounds;
  preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
  
  // If scrolled by a "reasonable" amount...
  CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
  if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
    
    // Compute the assets to start caching and to stop caching.
    NSMutableArray *addedIndexPaths = [NSMutableArray array];
    NSMutableArray *removedIndexPaths = [NSMutableArray array];
    
    [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
      NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
      [removedIndexPaths addObjectsFromArray:indexPaths];
    } addedHandler:^(CGRect addedRect) {
      NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
      [addedIndexPaths addObjectsFromArray:indexPaths];
    }];
    
    NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
    NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
    
    [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                        targetSize:AssetGridThumbnailSize
                                       contentMode:PHImageContentModeAspectFill
                                           options:nil];
    [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                       targetSize:AssetGridThumbnailSize
                                      contentMode:PHImageContentModeAspectFill
                                          options:nil];
    
    self.previousPreheatRect = preheatRect;
  }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect
                             andRect:(CGRect)newRect
                      removedHandler:(void (^)(CGRect removedRect))removedHandler
                        addedHandler:(void (^)(CGRect addedRect))addedHandler {
  if (CGRectIntersectsRect(newRect, oldRect)) {
    CGFloat oldMaxY = CGRectGetMaxY(oldRect);
    CGFloat oldMinY = CGRectGetMinY(oldRect);
    CGFloat newMaxY = CGRectGetMaxY(newRect);
    CGFloat newMinY = CGRectGetMinY(newRect);
    if (newMaxY > oldMaxY) {
      CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
      addedHandler(rectToAdd);
    }
    if (oldMinY > newMinY) {
      CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
      addedHandler(rectToAdd);
    }
    if (newMaxY < oldMaxY) {
      CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
      removedHandler(rectToRemove);
    }
    if (oldMinY < newMinY) {
      CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
      removedHandler(rectToRemove);
    }
  } else {
    addedHandler(newRect);
    removedHandler(oldRect);
  }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
  if (indexPaths.count == 0) { return nil; }
  
  NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
  for (NSIndexPath *indexPath in indexPaths) {
    if (0 < indexPath.item) {
      PHAsset *asset = [self assetAtIndexPath:indexPath];
      [assets addObject:asset];
    }
  }
  return assets;
}


#pragma mark - 
#pragma mark - Camera View Controller

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {

  if ([self.picker.delegate respondsToSelector:@selector(imagePickerController:imagePicker:didFinishPickingMediaWithInfo:)]) {
    [self.picker.delegate imagePickerController:self.picker imagePicker:picker didFinishPickingMediaWithInfo:info];
    return;
  }

  [picker dismissViewControllerAnimated:YES completion:^{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    __block NSString *placeholderLocalIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
      PHObjectPlaceholder *placeholderAsset = assetChangeRequest.placeholderForCreatedAsset;
      placeholderLocalIdentifier = placeholderAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
      if (!success) {
        NSLog(@"Error creating asset: %@", error);
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[placeholderLocalIdentifier] options:nil].firstObject;
          if (!asset) return;
          
          BOOL didSelectIndexPath = NO;
          for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
            if (![self isAssetIndexPath:indexPath]) continue;
            
            if ([[self assetAtIndexPath:indexPath] isEqual:asset]) {
              [self selectAssetAtIndexPath:indexPath];
              didSelectIndexPath = YES;
              break;
            }
          }
          if (![self.picker.selectedAssets containsObject:asset] && !didSelectIndexPath) {
            [self.picker selectAsset:asset];
          }
        });
      }
    }];
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  NSUInteger numberOfColumns;
  if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
    numberOfColumns = self.picker.numberOfColumnsInPortrait;
  } else {
    numberOfColumns = self.picker.numberOfColumnsInLandscape;
  }

  CGFloat width = (CGRectGetWidth(self.view.frame) - self.picker.minimumInteritemSpacing * (numberOfColumns - 1)) / numberOfColumns;
  AssetGridThumbnailSize = CGSizeMake(width, width);
  return AssetGridThumbnailSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return self.picker.minimumInteritemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  return self.picker.minimumLineSpacing;
}


#pragma mark -
#pragma mark - Camera Error

- (void)presentCameraAuthorizationError {
  NSString *title = NSLocalizedString(@"No permission", nil);
  NSString *message = NSLocalizedString(@"This app does not have access to your camera. You can enable access in Settings.", nil);
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self openAppSettings];
                                          }]];
  [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark -
#pragma mark - Open App Settings

- (void)openAppSettings {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}


@end