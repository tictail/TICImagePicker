//
//  TICImagePickerController.m
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "TICImagePickerController.h"
#import "TICAlbumsViewController.h"
#import "TICImageGridViewController.h"
#import "NSBundle+Tictail.h"

@import Photos;

@interface TICImagePickerController ()
<
UINavigationControllerDelegate,
UIPopoverPresentationControllerDelegate,
TICAlbumsViewController
>

@property (nonatomic, strong) TICAlbumsViewController *albumsViewController;
@property (nonatomic, strong) TICImageGridViewController *imageGridViewController;

@property (nonatomic, strong) UIButton *albumPickerButton;
@property (nonatomic, strong) UIBarButtonItem *titleButtonItem;

@property (nonatomic, strong) TICImagePickerViewModel *viewModel;

@end

@implementation TICImagePickerController

- (instancetype)init {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _selectedAssets = [[NSMutableArray alloc] init];

    //Default values:
    _shouldDisplaySelectionInfoToolbar = YES;
    _shouldDisplayNumberOfAssetsInAlbum = YES;
    _allowsMultipleSelection = YES;
    
    //Grid configuration:
    _numberOfColumnsInPortrait = 3;
    _numberOfColumnsInLandscape = 5;
    _minimumInteritemSpacing = 1.0;
    _minimumLineSpacing = 1.0;
    
    _assetsFetchOptions = [PHFetchOptions new];
    _assetsFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    _assetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeImage)];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [self init];
}

- (void)dealloc{
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
  if (!_albumsViewController.presentingViewController) {
    _albumsViewController = nil;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self addImageGridViewController];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
  if (status == PHAuthorizationStatusNotDetermined) {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self handleAuthorizationStatus:status];
      });
    }];
  } else {
    [self handleAuthorizationStatus:status];
  }
}

- (void)handleAuthorizationStatus:(PHAuthorizationStatus)status {
  if (status == PHAuthorizationStatusAuthorized) {
    [self setupAssetsGridViewController];
  } else {
    [self presentPhotoLibraryAuthorizationError];
  }
}

#pragma mark -
#pragma mark - Setup Navigation Controller

- (void)addImageGridViewController {  
  [self addChildViewController:self.imageGridViewController];
  [self.imageGridViewController.view setFrame:self.view.frame];
  [self.view addSubview:self.imageGridViewController.view];
  [self.imageGridViewController didMoveToParentViewController:self];
  
  [self setupNavigationItem:self.navigationItem];
}

- (void)setupAssetsGridViewController {
  [self setupToolbar];

  PHAssetCollection *assetCollection = self.albumsViewController.assetCollections.firstObject;
  [self updateGridViewController:self.imageGridViewController collection:assetCollection];
}


#pragma mark -
#pragma mark - Properties

- (TICImagePickerViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [TICImagePickerViewModel new];
    _viewModel.shouldDisplayNumberOfAssets = self.shouldDisplayNumberOfAssetsInAlbum;
    _viewModel.assetsFetchOptions = self.assetsFetchOptions;
    _viewModel.assetCollectionSubtypes = @[
                                           @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                           @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                           ];
  }
  return _viewModel;
}

#pragma mark -
#pragma mark - Album

- (TICAlbumsViewController *)albumsViewController {
  if (!_albumsViewController) {
    _albumsViewController = [[TICAlbumsViewController alloc] init];
    _albumsViewController.delegate = self;
    _albumsViewController.viewModel = self.viewModel;

    CGFloat width = CGRectGetWidth(self.view.bounds);
    _albumsViewController.preferredContentSize = CGSizeMake(width - 40, width);
    _albumsViewController.modalPresentationStyle = UIModalPresentationPopover;
  }
  return _albumsViewController;
}

- (void)toggleAlbumsPicker {
  UIView *sourceView = self.navigationItem.titleView;
  // Perhaps we're presented without a navigation controller?
  if (sourceView) {
    UIPopoverPresentationController *popover = [self.albumsViewController popoverPresentationController];
    popover.delegate = self;
    
    popover.sourceView = sourceView;
    popover.sourceRect = sourceView.bounds;
    popover.popoverLayoutMargins = UIEdgeInsetsMake(0, 20, 20, 20); // No-op but in case they fix it
    popover.permittedArrowDirections = UIPopoverArrowDirectionUnknown;
    if (self.presentedViewController == self.albumsViewController) {
      [self dismissViewControllerAnimated:YES completion:nil];
    } else {
      [self presentViewController:self.albumsViewController animated:YES completion:nil];
    }
  }
}

- (void)albumsViewController:(TICAlbumsViewController *)albumsViewController didSelectCollection:(PHAssetCollection *)assetCollection {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self updateGridViewController:self.imageGridViewController collection:assetCollection];
}

#pragma mark -
#pragma mark - Asset Grid

- (TICImageGridViewController *)imageGridViewController {
  if (!_imageGridViewController) {
    _imageGridViewController = [[TICImageGridViewController alloc] initWithPicker:self];
  }
  return _imageGridViewController;
}

- (void)updateGridViewController:(TICImageGridViewController *)gridViewController collection:(PHAssetCollection *)assetCollection {
  PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.assetsFetchOptions];
  gridViewController.assetsFetchResults = assetsFetchResult;
  gridViewController.assetCollection = assetCollection;
  [gridViewController.collectionView reloadData];
  [self updateAlbumPickerButtonWithTitle:assetCollection.localizedTitle];
}


#pragma mark - Select / Deselect Asset

- (void)selectAsset:(PHAsset *)asset {
  if (self.allowsMultipleSelection) {
    [self.selectedAssets insertObject:asset atIndex:self.selectedAssets.count];
  } else {
    [self.selectedAssets removeAllObjects];
    [self.selectedAssets addObject:asset];
  }
  
  [self updateDoneButton];
  
  if (self.shouldDisplaySelectionInfoToolbar) {
    [self updateToolbar];
  }
}

- (void)deselectAsset:(PHAsset *)asset {
  [self.selectedAssets removeObjectAtIndex:[self.selectedAssets indexOfObject:asset]];
  if (self.selectedAssets.count == 0) {
    [self updateDoneButton];
  }
  
  if (self.shouldDisplaySelectionInfoToolbar) {
    [self updateToolbar];
  }
}

- (void)clearSelection {
  [self.selectedAssets removeAllObjects];
  [self.imageGridViewController.collectionView reloadData];
}

#pragma mark -
#pragma mark - Actions

- (void)dismiss:(id)sender {
  if ([self.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
    [self.delegate imagePickerControllerDidCancel:self];
  }
  
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)finishPickingAssets:(id)sender {
  if ([self.delegate respondsToSelector:@selector(imagePickerController:didFinishPickingAssets:)]) {
    [self.delegate imagePickerController:self didFinishPickingAssets:[self.selectedAssets copy]];
  }
}

- (void)albumPickerButtonAction:(id)sender {
  [self toggleAlbumsPicker];
}


#pragma mark -
#pragma mark - NavigationBar

- (void)setupNavigationItem:(UINavigationItem *)navigationItem {
  navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishPickingAssets:)];
  navigationItem.rightBarButtonItem.enabled = (self.selectedAssets.count > 0);
  
  navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
  
  navigationItem.titleView = self.albumPickerButton;
}


- (UIButton *)albumPickerButton {
  if (!_albumPickerButton) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.albumPickerButton = button;
    [button addTarget:self action:@selector(albumPickerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  }
  return _albumPickerButton;
}

- (void)updateAlbumPickerButtonWithTitle:(NSString *)title {
  // Add some space for the arrow
  if (!title) return;
  
  title = [title stringByAppendingString:@" "];
  NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
  NSTextAttachment *textAttachment = [NSTextAttachment new];
  UIImage *image = [UIImage imageNamed:@"TICAlbumPickerArrow"
                              inBundle:[NSBundle tic_bundleForClass:self.class]
         compatibleWithTraitCollection:nil];
  textAttachment.image = image;
  textAttachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
  [attributedTitle appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
  [self.albumPickerButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
  [self.albumPickerButton sizeToFit];
}

- (void)updateDoneButton {
  self.navigationItem.rightBarButtonItem.enabled = (self.selectedAssets.count > 0);
}


#pragma mark -
#pragma mark - Toolbar

- (void)setupToolbar {
  self.imageGridViewController.toolbarItems = self.toolbarItems;
}

- (void)updateToolbar {
  self.titleButtonItem.title = [self toolbarTitle];
  [self.navigationController setToolbarHidden:(self.selectedAssets.count == 0) animated:YES];
}

- (NSString *)toolbarTitle {
  NSInteger imageCount = self.selectedAssets.count;
  NSBundle *bundle = [NSBundle tic_bundleForClass:self.class];
  return [[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"%d-photos-selected", @"TICImagePicker", bundle, @"%d is a number"), imageCount]
          capitalizedStringWithLocale:[NSLocale currentLocale]];
}

- (UIBarButtonItem *)titleButtonItem {
  if (!_titleButtonItem) {
    _titleButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.toolbarTitle
                                                        style:UIBarButtonItemStylePlain
                                                       target:nil
                                                       action:nil];
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName : [UIColor blackColor] };
    
    [_titleButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [_titleButtonItem setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    [_titleButtonItem setEnabled:NO];
  }
  return _titleButtonItem;
}

- (UIBarButtonItem *)flexibleSpaceButtonItem {
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (NSArray *)toolbarItems {
  return @[[self flexibleSpaceButtonItem], [self titleButtonItem], [self flexibleSpaceButtonItem]];
}


#pragma mark -
#pragma mark - Popover

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
  return UIModalPresentationNone;
}


#pragma mark -
#pragma mark - Errors

- (void)presentPhotoLibraryAuthorizationError {
  NSString *title = NSLocalizedString(@"No permission", nil);
  NSString *message = NSLocalizedString(@"This app does not have access to your photos. You can enable access in Settings.", nil);
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
