//
//  ZBFlipsideViewController.h
//  Tiles
//
//  Created by Константин Забелин on 13.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBFlipsideViewController;


@protocol ZBFlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(ZBFlipsideViewController *)controller;

@end



@interface ZBFlipsideViewController : UIViewController

@property (assign, nonatomic) id<ZBFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
