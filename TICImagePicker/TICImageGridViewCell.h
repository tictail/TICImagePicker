//
//  TICImageGridViewCell.h
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

@import UIKit;

@interface TICImageGridViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIColor *selectedColor;

@end