//
//  TICAlbumCell.m
//  TICImagePickerController
//
//  Created by Martin Hwasser on 10/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "TICAlbumCell.h"

@interface TICAlbumCell ()

@end

@implementation TICAlbumCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {

    self.backgroundColor = [UIColor clearColor];
    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    [self.contentView addSubview:self.thumbnailImageView];
    [self.contentView addSubview:self.titleLabel];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    vibrancyView.frame = self.bounds;
    vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.contentView insertSubview:vibrancyView atIndex:0];

    [vibrancyView.contentView addSubview:self.countLabel];
  }
  
  return self;
}

- (UIImageView *)thumbnailImageView {
  if (!_thumbnailImageView) {
    _thumbnailImageView = [UIImageView new];
    _thumbnailImageView.clipsToBounds = YES;
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
  }
  return _thumbnailImageView;
}

- (UIFont *)titleLabelFont {
  if (!_titleLabelFont) {
    UIFont *titleLabelFont = [[self.class appearance] titleLabelFont];
    if (!titleLabelFont) {
      titleLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    self.titleLabelFont = titleLabelFont;
  }
  return _titleLabelFont;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [UILabel new];
    _titleLabel.numberOfLines = 2;
    _titleLabel.textColor = [UIColor colorWithWhite:0 alpha:.8];
    _titleLabel.font = self.titleLabelFont;
  }
  return _titleLabel;
}

- (UIFont *)countLabelFont {
  if (!_countLabelFont) {
    UIFont *countLabelFont = [[self.class appearance] countLabelFont];
    if (!countLabelFont) {
      countLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }
    self.countLabelFont = countLabelFont;
  }
  return _countLabelFont;
}

- (UILabel *)countLabel {
  if (!_countLabel) {
    _countLabel = [UILabel new];
    _countLabel.font = self.countLabelFont;
  }
  return _countLabel;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat height = TICAlbumCellImageDiameter;
  CGFloat xMargin = 15;
  CGFloat yMargin = roundf((CGRectGetHeight(self.contentView.frame) - height) / 2);
  CGRect frame = CGRectMake(xMargin, yMargin, height, height);
  self.thumbnailImageView.frame = frame;
  self.thumbnailImageView.layer.cornerRadius = CGRectGetHeight(self.thumbnailImageView.frame) * 0.5;

  CGFloat labelMargin = 15;
  
  [self.countLabel sizeToFit];
  frame = self.countLabel.frame;
  frame.origin.x = CGRectGetWidth(self.contentView.frame) - CGRectGetWidth(frame) - xMargin;
  frame.origin.y = CGRectGetMidY(self.contentView.bounds) - CGRectGetHeight(frame) / 2;
  self.countLabel.frame = frame;

  CGSize sizeConstraint = CGSizeMake(CGRectGetMinX(self.countLabel.frame) - CGRectGetMaxX(self.thumbnailImageView.frame) - 2 * 5,
                                     CGRectGetHeight(self.contentView.frame));
  CGSize size = [self.titleLabel sizeThatFits:sizeConstraint];
  frame = self.titleLabel.frame;
  frame.size = size;
  frame.origin.x = CGRectGetMaxX(self.thumbnailImageView.frame) + labelMargin;
  frame.origin.y = (CGRectGetHeight(self.contentView.bounds) - size.height) * 0.5;
  self.titleLabel.frame = frame;
}


@end
