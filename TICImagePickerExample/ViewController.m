//
//  ViewController.m
//  TICImagePickerExample
//
//  Created by Martin Hwasser on 12/06/15.
//  Copyright (c) 2015 Tictail. All rights reserved.
//

#import "ViewController.h"
#import "TICImagePickerController.h"

@interface ViewController () <TICImagePickerControllerDelegate>

@property (nonatomic, strong) TICImagePickerController *imagePickerController;

@end

@implementation ViewController

+ (void)initialize {
  if (self == ViewController.class) {
    [[TICAssetGridViewCell appearance] setSelectedColor:[[UIColor greenColor] colorWithAlphaComponent:0.4]];
    [[TICAlbumCell appearance] setTitleLabelFont:[UIFont systemFontOfSize:20]];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [button setTitle:@"TICImagePickerController" forState:UIControlStateNormal];
  [button sizeToFit];
  [self.view addSubview:button];
  button.center = self.view.center;
  [button addTarget:self action:@selector(presentImagePickerController:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)presentImagePickerController:(id)sender {
  TICImagePickerController *imagePickerController = [TICImagePickerController new];
  self.imagePickerController = imagePickerController;
  imagePickerController.delegate = self;
  [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)assetsPickerControllerDidCancel:(TICImagePickerController *)picker {
  NSLog(@"Cancelling dismisses automatically.");
}

- (void)assetsPickerController:(TICImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets {
  NSLog(@"Did finish picking assets: %@", assets);
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
