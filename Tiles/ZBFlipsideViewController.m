//
//  ZBFlipsideViewController.m
//  Tiles
//
//  Created by Константин Забелин on 13.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "ZBFlipsideViewController.h"

@implementation ZBFlipsideViewController

@synthesize delegate = _delegate;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end
