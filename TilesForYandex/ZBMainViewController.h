//
//  ZBMainViewController.h
//  TilesForYandex
//
//  Created by Константин Забелин on 13.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "ZBFlipsideViewController.h"
#import "ZBTileScrollView.h"

@interface ZBMainViewController : UIViewController <ZBFlipsideViewControllerDelegate, ZBTileScrollViewDataSource, ZBTileScrollViewDelegate>

- (IBAction)showInfo:(id)sender;

@end
