//
//  TICImagePickerController.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

@import UIKit;
@import Photos;

#import "TICImageGridViewCell.h"
#import "TICAlbumCell.h"
#import "TICCameraGridViewCell.h"

@protocol TICImagePickerControllerDelegate;


/**
 *  A controller that allows picking multiple photos and videos from user's photo library.
 */
@interface TICImagePickerController : UIViewController

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 *  The assets picker’s delegate object.
 */
@property (nonatomic, weak) id <TICImagePickerControllerDelegate> delegate;

/**
 *  It contains the selected `PHAsset` objects. The order of the objects is the selection order.
 *
 *  You can add assets before presenting the picker to show the user some preselected assets.
 */
@property (nonatomic, strong) NSMutableArray *selectedAssets;


/** UI Customizations **/

/**
 *  An optional PHFetchOptions for assets.
 *  The default options filter out everything but photos, and sort assets by descending creationDate.
 */
@property (nonatomic, strong) PHFetchOptions *assetsFetchOptions;


/**
 *  Determines whether or not a toolbar with info about user selection is shown.
 *  The InfoToolbar is visible by default.
 */
@property (nonatomic) BOOL shouldDisplaySelectionInfoToolbar;

/**
 *  Determines whether or not the number of assets is shown in the Album list.
 *  The number of assets is visible by default.
 */
@property (nonatomic, assign) BOOL shouldDisplayNumberOfAssetsInAlbum;

/**
 *  Determines whether or not to use the default UIImagePickerController camera.
 *  By default, the picker displays a UIImagePickerController for taking photos.
 *  If set to YES, implement -imagePickerController:didTapCameraCell: and respond accordingly.
 */
@property (nonatomic, assign) BOOL shouldUseCustomCameraController;


/**
 *  Whether or not to allow multiple selection.
 */
@property (nonatomic, assign) BOOL allowsMultipleSelection;


/**
 *  Grid customizations:
 *
 *  - numberOfColumnsPortrait: Number of columns in portrait (3 by default)
 *  - numberOfColumnsLandscape: Number of columns in portrait (5 by default)
 *  - minimumInteritemSpacing: Horizontal and vertical minimum space between grid cells (1.0 by default)
 */
@property (nonatomic) NSInteger numberOfColumnsInPortrait, numberOfColumnsInLandscape;
@property (nonatomic) CGFloat minimumInteritemSpacing, minimumLineSpacing;


/**
 *  Managing Asset Selection
 */
- (void)selectAsset:(PHAsset *)asset;
- (void)deselectAsset:(PHAsset *)asset;

/**
 *  Clears any existing selection and reloads the collectionView.
 */
- (void)clearSelection;

/**
 *  User finish Actions
 */
- (void)dismiss:(id)sender;
- (void)finishPickingAssets:(id)sender;

@end



@protocol TICImagePickerControllerDelegate <NSObject>

@optional

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked PHAssets objects.
 */

- (void)imagePickerController:(TICImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets;

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *  @param picker The controller object managing the assets picker interface.
 */
- (void)imagePickerControllerDidCancel:(TICImagePickerController *)picker;


/**
 *  @name Enabling Assets
 */

/**
 *  Ask the delegate if the specified asset should be shown.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be shown.
 *
 *  @return `YES` if the asset should be shown or `NO` if it should not.
 */

- (BOOL)imagePickerController:(TICImagePickerController *)picker shouldShowAsset:(PHAsset *)asset;


/**
 *  @name Managing the Selected Assets
 */

/**
 *  Asks the delegate if the specified asset should be selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be selected.
 *
 *  @return `YES` if the asset should be selected or `NO` if it should not.
 *
 */
- (BOOL)imagePickerController:(TICImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset;

/**
 *  Tells the delegate that the asset was selected.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was selected.
 *
 */
- (void)imagePickerController:(TICImagePickerController *)picker didSelectAsset:(PHAsset *)asset;

/**
 *  Asks the delegate if the specified asset should be deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be deselected.
 *
 *  @return `YES` if the asset should be deselected or `NO` if it should not.
 *
 */
- (BOOL)imagePickerController:(TICImagePickerController *)picker shouldDeselectAsset:(PHAsset *)asset;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was deselected.
 *
 */
- (void)imagePickerController:(TICImagePickerController *)picker didDeselectAsset:(PHAsset *)asset;

/**
 *  Tells the delegate that the UIImagePickerController did finish picking media. If the delegate
 *  responds to this method, it is also responsible for dismissing the picker.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param imagePickerController The image picker that took an image using the camera.
 *  @param infoDictionary the info dictionary containing the info about the image taken.
 *
 */
- (void)imagePickerController:(TICImagePickerController *)picker
                   imagePicker:(UIImagePickerController *)imagePickerController
 didFinishPickingMediaWithInfo:(NSDictionary *)infoDictionary;

/**
 *  Tells the delegate that the camera cell was tapped.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param cell The cell that was tapped.
 *
 */
- (void)imagePickerController:(TICImagePickerController *)picker
              didTapCameraCell:(TICCameraGridViewCell *)cell;

@end