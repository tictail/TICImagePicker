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


@protocol TICImagePickerControllerDelegate;


/**
 *  A controller that allows picking multiple photos and videos from user's photo library.
 */
@interface TICImagePickerController : UIViewController

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
 *  Grid customizations:
 *
 *  - columnsPortrait: Number of columns in portrait (3 by default)
 *  - minimumInteritemSpacing: Horizontal and vertical minimum space between grid cells (2.0 by default)
 */
@property (nonatomic) NSInteger columnsInPortrait;
@property (nonatomic) CGFloat minimumInteritemSpacing;


@property (nonatomic, strong) UINavigationController *childNavigationController;

/**
 *  Managing Asset Selection
 */
- (void)selectAsset:(PHAsset *)asset;
- (void)deselectAsset:(PHAsset *)asset;

/**
 *  User finish Actions
 */
- (void)dismiss:(id)sender;
- (void)finishPickingAssets:(id)sender;

@end



@protocol TICImagePickerControllerDelegate <NSObject>

/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked PHAssets objects.
 */

- (void)assetsPickerController:(TICImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets;


@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *  @param picker The controller object managing the assets picker interface.
 */
- (void)assetsPickerControllerDidCancel:(TICImagePickerController *)picker;


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

- (BOOL)assetsPickerController:(TICImagePickerController *)picker shouldShowAsset:(PHAsset *)asset;


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
- (BOOL)assetsPickerController:(TICImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset;

/**
 *  Tells the delegate that the asset was selected.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was selected.
 *
 */
- (void)assetsPickerController:(TICImagePickerController *)picker didSelectAsset:(PHAsset *)asset;

/**
 *  Asks the delegate if the specified asset should be deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be deselected.
 *
 *  @return `YES` if the asset should be deselected or `NO` if it should not.
 *
 */
- (BOOL)assetsPickerController:(TICImagePickerController *)picker shouldDeselectAsset:(PHAsset *)asset;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was deselected.
 *
 */
- (void)assetsPickerController:(TICImagePickerController *)picker didDeselectAsset:(PHAsset *)asset;


/**
 *  @name Managing Asset Highlighting
 */

/**
 *  Asks the delegate if the specified asset should be highlighted.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be highlighted.
 *
 *  @return `YES` if the asset should be highlighted or `NO` if it should not.
 */
- (BOOL)assetsPickerController:(TICImagePickerController *)picker shouldHighlightAsset:(PHAsset *)asset;

/**
 *  Tells the delegate that asset was highlighted.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was highlighted.
 *
 */
- (void)assetsPickerController:(TICImagePickerController *)picker didHighlightAsset:(PHAsset *)asset;


/**
 *  Tells the delegate that the highlight was removed from the asset.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that had its highlight removed.
 *
 */
- (void)assetsPickerController:(TICImagePickerController *)picker didUnhighlightAsset:(PHAsset *)asset;




@end