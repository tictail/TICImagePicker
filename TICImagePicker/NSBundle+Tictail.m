//
//  NSBundle+Tictail.m
//  TICImagePickerExample
//
//  Created by Martin Hwasser on 12/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "NSBundle+Tictail.h"

@implementation NSBundle (Tictail)

+ (NSString *)tic_bundlePath {
  return [[NSBundle mainBundle] pathForResource:@"TICImagePicker" ofType:@"bundle"];
}

+ (NSBundle *)tic_bundle {
  return [NSBundle bundleWithPath:[self tic_bundlePath]];
}

@end
