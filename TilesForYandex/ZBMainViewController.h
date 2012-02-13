//
//  ZBMainViewController.h
//  TilesForYandex
//
//  Created by Константин Забелин on 13.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "ZBFlipsideViewController.h"

@interface ZBMainViewController : UIViewController <ZBFlipsideViewControllerDelegate, UIScrollViewDelegate>

@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)showInfo:(id)sender;

@end
