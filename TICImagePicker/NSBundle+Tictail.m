//
//  NSBundle+Tictail.m
//  TICImagePickerExample
//
//  Created by Martin Hwasser on 15/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "NSBundle+Tictail.h"

@implementation NSBundle (Tictail)

+ (NSBundle *)tic_bundleForClass:(Class)class {
  NSBundle *bundle = [NSBundle bundleForClass:class];
  NSString *bundlePath = [bundle pathForResource:@"TICImagePicker" ofType:@"bundle"];
  if (bundlePath) {
    bundle = [NSBundle bundleWithPath:bundlePath];
  }
  return bundle;
}

@end
