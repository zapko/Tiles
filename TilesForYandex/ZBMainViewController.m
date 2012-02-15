//
//  ZBMainViewController.m
//  TilesForYandex
//
//  Created by Константин Забелин on 13.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#define kTileSize	128
#define kTileNum	100


#import "ZBMainViewController.h"

@implementation ZBMainViewController

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	ZBTileScrollView *tileScrollView = [[ZBTileScrollView alloc] initWithFrame:self.view.bounds 
															horizontalTilesNum:kTileNum 
															  verticalTilesNum:kTileNum];
	tileScrollView.tileSize		= CGSizeMake(kTileSize, kTileSize);
	tileScrollView.dataSource	= self;
	tileScrollView.tileDelegate	= self;
	
	tileScrollView.multipleTouchEnabled = YES;
	tileScrollView.minimumZoomScale = 0.5;
	tileScrollView.maximumZoomScale = 2.0;
	
	[self.view addSubview:tileScrollView];

	[tileScrollView release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Behavior -

#pragma mark ZBTilesScrollView data source

- (UIImage *)imageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
		// TODO: implement
	return [UIImage imageNamed:@"tile.png"];
}

- (void)imageNoLongerNeededForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
		// TODO: implement
	return;
}

#pragma mark Scroll delegate

- (void)tileScrollViewDidScroll:(UIScrollView *)scrollView
{
	NSLog(@"Scroll delegate from view controller");
}

#pragma mark Flipside View

- (void)flipsideViewControllerDidFinish:(ZBFlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{    
    ZBFlipsideViewController *controller = [[[ZBFlipsideViewController alloc] initWithNibName:@"ZBFlipsideViewController" bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
}

@end
