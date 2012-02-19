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
#import "DownloadManager.h"

@interface ZBMainViewController()

@property (nonatomic, retain) NSMutableSet *		loadedImages;
@property (nonatomic, retain) ZBTileScrollView *	tileScrollView;
@property (nonatomic, retain) DownloadManager *		downloadManager;

@end



@implementation ZBMainViewController

@synthesize loadedImages	= loadedImages_;
@synthesize tileScrollView	= tileScrollView_;
@synthesize downloadManager = downloadManager_;

#pragma mark - Lazy objects

- (NSMutableSet *) loadedImages
{
	if (!loadedImages_)
	{
		loadedImages_ = [[NSMutableSet alloc] init];
	}
	return loadedImages_;
}

- (ZBTileScrollView *) tileScrollView
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

- (DownloadManager *) downloadManager
{
	if (!downloadManager_)
	{
		downloadManager_ = [[DownloadManager alloc] init];
		downloadManager_.numberOfSimultaneousLoadings = 5; // This number should depend on the average size of tiles, maybe on the connection speed
	}
	return downloadManager_;
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
		// TODO: try to save some memory
}

- (void) dealloc 
{
	[loadedImages_	 release];
	[tileScrollView_ release];
	
	[super dealloc];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	UIView*				view			= self.view;
	ZBTileScrollView*	tileScrollView	= self.tileScrollView;

	tileScrollView.frame = view.bounds;
		
	[view addSubview:		tileScrollView];
	[view sendSubviewToBack:tileScrollView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(imageLoaded:)
												 name:ZBDownloadComplete
											   object:self.downloadManager];
}

- (void) viewDidUnload
{
	[tileScrollView_ release];
	tileScrollView_ = nil;
	
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Flipside View

- (void) flipsideViewControllerDidFinish:(ZBFlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction) showInfo:(id)sender
{    
    ZBFlipsideViewController *controller = [[[ZBFlipsideViewController alloc] initWithNibName:@"ZBFlipsideViewController" bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
}

#pragma mark - Tiles loading

- (UIImage *) imageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature = [NSString stringWithFormat:@"%d%@%d", horIndex, separator, verIndex];

		// TODO: ask cache for the image
	BOOL imageIsLoaded			= NO;
	NSMutableSet * loadedImages = self.loadedImages;
	NSDictionary * imageInfo	= nil;
	
	for (imageInfo in loadedImages)
	{
		if ([imageSignature isEqualToString:[imageInfo objectForKey:@"signature"]])
		{
			imageIsLoaded = YES;
			break;
		}
	}
	
	if (!imageIsLoaded)
	{
		[self.downloadManager queueLoadinImageForSignature:imageSignature];

		return [UIImage imageNamed:@"placeholder.png"];
	}
	else
	{
			// TODO: get image from cache
			// TODO: check for image validity and remove file if it is corrupted
		return [UIImage imageWithContentsOfFile:[imageInfo objectForKey:@"path"]];
	}
}
	 
- (void) imageLoaded:(NSNotification *)note
{
		// TODO: write loaded image to cache
	NSDictionary * imageInfo = note.userInfo;
	
	[self.loadedImages addObject:imageInfo];
	
	if (!tileScrollView_) { return; }
	
	NSArray* components = [[imageInfo objectForKey:@"signature"] componentsSeparatedByString:separator];
	assert([components count] == 2);
	NSUInteger horIndex = [[components objectAtIndex:0] integerValue];
	NSUInteger verIndex = [[components objectAtIndex:1] integerValue];
	
	[self.tileScrollView reloadImageForTileAtHorIndex:horIndex verIndex:verIndex];
}

- (void) imageNoLongerNeededForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature = [NSString stringWithFormat:@"%d%@%d", horIndex, separator, verIndex];

	[self.downloadManager dequeueLoadingImageForSignature:imageSignature];
}

@end
