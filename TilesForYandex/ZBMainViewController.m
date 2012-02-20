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
#import "TilesCache.h"
#import "NSString+ImageLoadingSignatures.h"

@interface ZBMainViewController()

@property (nonatomic, retain)	NSMutableSet *		loadedImages;
@property (nonatomic, retain)	ZBTileScrollView *	tileScrollView;
@property (nonatomic, retain)	DownloadManager *	downloadManager;
@property (nonatomic)			ZBCacheRef			cache;

@end



@implementation ZBMainViewController

@synthesize loadedImages	= loadedImages_;
@synthesize tileScrollView	= tileScrollView_;
@synthesize downloadManager = downloadManager_;
@synthesize cache			= cache_;

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
		downloadManager_.networkActivityDelegate = self;
		downloadManager_.numberOfSimultaneousLoadings = 7;
	}
	return downloadManager_;
}

- (ZBCacheRef) cache
{
	if (!cache_)
	{
		NSArray *cachePaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		NSString *cachePath = [NSString stringWithFormat:@"%@/", [cachePaths objectAtIndex:0]];
		cache_ = ZBCacheCreate( [cachePath UTF8String], [ZBTileImageExtension UTF8String] );
		assert( cache_ );
	}
	return cache_;
}

- (void) setCache:(ZBCacheRef)cache
{
	ZBCacheDelete(cache_);
	cache_ = cache;
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

	self.cache = nil;
}

- (void) dealloc 
{
	self.cache = nil;
	
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
											 selector:@selector(imageLoadingFinished:)
												 name:ZBDownloadComplete
											   object:self.downloadManager];
}

- (void) viewDidUnload
{
	self.tileScrollView = nil;
	
    [super viewDidUnload];
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

	UIImage	*image = nil;
	
	char file[ZBFilePathLength] = { 0 };
	int fileExists = ZBCacheGetFileForSignature(self.cache, [imageSignature UTF8String], file);
	if (fileExists) 
	{ 
		NSString *filePath = [NSString stringWithCString:file encoding:NSUTF8StringEncoding];
		image = [UIImage imageWithContentsOfFile:filePath];
	}
		
		// If file is corrupted it should be deleted and a new one downloaded
	if (fileExists && !image) { ZBCacheRemoveFileForSignature(self.cache, [imageSignature UTF8String]); }
		
	if (!image)
	{
		[self.downloadManager queueLoadinImageForSignature:imageSignature];

		return [UIImage imageNamed:@"placeholder.png"];
	}
	else
	{
		return image;
	}
}
	 
- (void) imageLoadingFinished:(NSNotification *)note
{
	NSDictionary * imageInfo = note.userInfo;

	NSString *signature = [imageInfo objectForKey:@"signature"];
	NSString *path		= [imageInfo objectForKey:@"path"];

	if (!path) // Image was not loaded
	{
		NSLog(@"Image for signature %@ was not load,try to check the url %@", signature, [signature URLforImageFromSignature]);
		return; 
	} 
	
	assert( signature );
	assert( path );

	ZBCacheSetFileForSignature(self.cache, [path UTF8String], [signature UTF8String], YES);
		
	if (!tileScrollView_) { return; }
	
	NSArray* components = [signature componentsSeparatedByString:separator];
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

#pragma mark - Network activity observing

- (void) startsUsingNetwork
{
	if ([NSThread isMainThread])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
	else {
		[self performSelectorOnMainThread:@selector(startsUsingNetwork) withObject:nil waitUntilDone:NO];
	}
}

- (void) stopsUsingNetwork
{
	if ([NSThread isMainThread])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	else {
		[self performSelectorOnMainThread:@selector(stopsUsingNetwork) withObject:nil waitUntilDone:NO];
	}
}

@end
