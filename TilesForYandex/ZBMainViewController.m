//
//  ZBMainViewController.m
//  TilesForYandex
//
//  Created by Константин Забелин on 13.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#define kTileSize	128
#define kTileNum	100

static NSString* separator = @"_";

#import "ZBMainViewController.h"

@interface ZBMainViewController()

@property (nonatomic, retain) NSMutableSet *		loadedImages;
@property (nonatomic, retain) ZBTileScrollView *	tileScrollView;

@end



@implementation ZBMainViewController

@synthesize loadedImages	= loadedImages_;
@synthesize tileScrollView	= tileScrollView_;

- (NSMutableSet *)loadedImages
{
	if (!loadedImages_)
	{
		loadedImages_ = [[NSMutableSet alloc] init];
	}
	return loadedImages_;
}

- (ZBTileScrollView *)tileScrollView
{
	if (!tileScrollView_)
	{
		tileScrollView_ = [[ZBTileScrollView alloc] initWithFrame:CGRectZero
											   horizontalTilesNum:kTileNum 
												 verticalTilesNum:kTileNum];
		tileScrollView_.tileSize	= CGSizeMake(kTileSize, kTileSize);
		tileScrollView_.dataSource	= self;
	}
	return tileScrollView_;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc 
{
	[loadedImages_ release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UIView*				view			= self.view;
	ZBTileScrollView*	tileScrollView	= self.tileScrollView;

	tileScrollView.frame = view.bounds;
		
	[view addSubview:		tileScrollView];
	[view sendSubviewToBack:tileScrollView];
}

- (void)viewDidUnload
{
	[tileScrollView_ release];
	tileScrollView_ = nil;
	
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
	NSString* imageSignature = [NSString stringWithFormat:@"%d%@%d", horIndex, separator, verIndex];

		// TODO: ask cache for the image
	if (![self.loadedImages containsObject:imageSignature])
	{
			// TODO: ask loader to load an image
		[self performSelector:@selector(imageLoaded:) withObject:imageSignature afterDelay:1];

		return [UIImage imageNamed:@"placeholder.png"];
	}
	else
	{
		return [UIImage imageNamed:@"tile.png"];
	}
}

- (void)imageLoaded:(NSString *)imageSignature
{
		// TODO: write loaded image to cache
	[self.loadedImages addObject:imageSignature];
	
	if (!tileScrollView_) { return; }
	
	NSArray* components = [imageSignature componentsSeparatedByString:separator];
	assert([components count] == 2);
	NSUInteger horIndex = [[components objectAtIndex:0] integerValue];
	NSUInteger verIndex = [[components objectAtIndex:1] integerValue];
	
	[self.tileScrollView setImageForTileAtHorIndex:horIndex verIndex:verIndex];
}

- (void)imageNoLongerNeededForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature = [NSString stringWithFormat:@"%d%@%d", horIndex, separator, verIndex];
		// TODO: cancel loader from loading image with this signature
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(imageLoaded:) object:imageSignature];
	
	return;
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
