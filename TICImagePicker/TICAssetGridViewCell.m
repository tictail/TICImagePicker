//
//  TICImageGridViewCell.m
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "TICAssetGridViewCell.h"

@interface TICAssetGridViewCell ()
@end


@implementation TICAssetGridViewCell

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
    
    CGFloat cellSize = self.contentView.bounds.size.width;

    _imageView = [UIImageView new];
    _imageView.frame = CGRectMake(0, 0, cellSize, cellSize);
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:_imageView];
    
    _overlayView = [[UIView alloc] initWithFrame:self.bounds];
    _overlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _overlayView.backgroundColor = self.selectedColor;
    _overlayView.hidden = YES;
    [self.contentView addSubview:_overlayView];
  }
  return self;
}

- (UIColor *)selectedColor {
  if (!_selectedColor) {
    UIColor *selectedColor = [[self.class appearance] selectedColor];
    if (!selectedColor) {
      selectedColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
    }
    _selectedColor = selectedColor;
  }
  return _selectedColor;
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];
  
  self.overlayView.hidden = !selected;
}

@end