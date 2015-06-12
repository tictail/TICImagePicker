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
MHWAlbumsViewController
>

@property (nonatomic, strong) TICAlbumsViewController *albumsViewController;
@property (nonatomic, strong) TICImageGridViewController *imageGridViewController;

@property (nonatomic, strong) UIButton *albumPickerButton;
@property (nonatomic, strong) UIBarButtonItem *titleButtonItem;

@end

@implementation TICImagePickerController

- (id)init {
  if (self = [super init]) {
    _selectedAssets = [[NSMutableArray alloc] init];

    //Default values:
    _shouldDisplaySelectionInfoToolbar = YES;
    _shouldDisplayNumberOfAssetsInAlbum = YES;
    
    //Grid configuration:
    _columnsInPortrait = 3;
    _minimumInteritemSpacing = 2.0;
    
    _assetsFetchOptions = [PHFetchOptions new];
    _assetsFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    _assetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeImage)];
  }
  return self;
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
  
  self.view.backgroundColor = [UIColor redColor];
  
  [self setupChildNavigationController];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
  if (status == PHAuthorizationStatusNotDetermined) {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      [self handleAuthorizationStatus:status];
    }];
  } else {
    [self handleAuthorizationStatus:status];
  }
}

- (void)handleAuthorizationStatus:(PHAuthorizationStatus)status {
  if (status == PHAuthorizationStatusAuthorized) {
    [self setupAssetsGridViewController];
  } else {
    [self displayAuthorizationError];
  }

}

#pragma mark -
#pragma mark - Setup Navigation Controller

- (void)setupChildNavigationController {
  self.childNavigationController = [[UINavigationController alloc] initWithRootViewController:self.imageGridViewController];
  self.childNavigationController.delegate = self;
  
  [self.childNavigationController willMoveToParentViewController:self];
  [self.childNavigationController.view setFrame:self.view.frame];
  [self.view addSubview:self.childNavigationController.view];
  [self addChildViewController:self.childNavigationController];
  [self.childNavigationController didMoveToParentViewController:self];
}

- (void)setupAssetsGridViewController {
  [self setupNavigationItem:self.imageGridViewController.navigationItem];
  [self setupToolbar];
  
  PHFetchResult *collectionFetchResult = self.albumsViewController.collectionsFetchResults.firstObject;
  PHAssetCollection *assetCollection = collectionFetchResult.firstObject;
  [self updateGridViewController:self.imageGridViewController collection:assetCollection];
}

- (void)displayAuthorizationError {
  NSLog(@"do nothing");
}

#pragma mark -
#pragma mark - Album

- (TICAlbumsViewController *)albumsViewController {
  if (!_albumsViewController) {
    _albumsViewController = [[TICAlbumsViewController alloc] init];
    _albumsViewController.delegate = self;
    _albumsViewController.shouldDisplayNumberOfAssets = self.shouldDisplayNumberOfAssetsInAlbum;
    _albumsViewController.assetsFetchOptions = self.assetsFetchOptions;

    CGFloat width = CGRectGetWidth(self.view.bounds);
    _albumsViewController.preferredContentSize = CGSizeMake(width - 40, width);
    _albumsViewController.modalPresentationStyle = UIModalPresentationPopover;
  }
  return _albumsViewController;
}

- (void)toggleAlbumsPicker {
  UIPopoverPresentationController *popover = [self.albumsViewController popoverPresentationController];
  popover.delegate = self;
  
  UIView *sourceView = self.imageGridViewController.navigationItem.titleView;
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
  [self updateAlbumPickerButtonWithTitle:assetCollection.localizedTitle];
}


#pragma mark - Select / Deselect Asset

- (void)selectAsset:(PHAsset *)asset {
  [self.selectedAssets insertObject:asset atIndex:self.selectedAssets.count];
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


#pragma mark -
#pragma mark - Actions

- (void)dismiss:(id)sender {
  if ([self.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)]) {
    [self.delegate assetsPickerControllerDidCancel:self];
  }
  
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)finishPickingAssets:(id)sender {
  if ([self.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssets:)]) {
    [self.delegate assetsPickerController:self didFinishPickingAssets:self.selectedAssets];
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
  title = [title stringByAppendingString:@" "];
  NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
  NSTextAttachment *textAttachment = [NSTextAttachment new];
  UIImage *image = [UIImage imageNamed:@"TICAlbumPickerArrow"
                              inBundle:[NSBundle tic_bundle]
         compatibleWithTraitCollection:nil];
  textAttachment.image = image;
  textAttachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
  [attributedTitle appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
  [self.albumPickerButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
  [self.albumPickerButton sizeToFit];
}

- (void)updateDoneButton {
  self.imageGridViewController.navigationItem.rightBarButtonItem.enabled = (self.selectedAssets.count > 0);
}


#pragma mark -
#pragma mark - Toolbar

- (void)setupToolbar {
  self.imageGridViewController.toolbarItems = self.toolbarItems;
}

- (void)updateToolbar {
  self.titleButtonItem.title = [self toolbarTitle];
  [self.imageGridViewController.navigationController setToolbarHidden:(self.selectedAssets.count == 0) animated:YES];
}

- (NSString *)toolbarTitle {
  NSInteger imageCount = self.selectedAssets.count;
  return [[NSString localizedStringWithFormat:NSLocalizedString(@"%d-photos-selected", @"%d is a number"), imageCount]
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

@end
