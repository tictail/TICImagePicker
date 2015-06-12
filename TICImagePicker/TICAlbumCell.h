//
//  TICAlbumCell.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

@import UIKit;
@import Photos;

static CGFloat const MHWAlbumCellImageRadius = 70;

@interface TICAlbumCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIFont *titleLabelFont UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIFont *countLabelFont UI_APPEARANCE_SELECTOR;

@end
