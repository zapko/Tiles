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
#import "TilesCache.h"
#import "NSString+ImageLoadingSignatures.h"


@interface ZBMainViewController()

@property (nonatomic, retain)	NSMutableSet *		loadedImages;
@property (nonatomic, retain)	ZBTileScrollView *	tileScrollView;
@property (nonatomic, retain)	DownloadManager *	downloadManager;
@property (nonatomic, retain)	NSOperationQueue*	operationQueue;
@property (nonatomic)			ZBCacheRef			cache;

@end


@implementation ZBMainViewController

@synthesize loadedImages	= loadedImages_;
@synthesize tileScrollView	= tileScrollView_;
@synthesize downloadManager = downloadManager_;
@synthesize operationQueue	= operationQueue_;
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
		downloadManager_.numberOfSimultaneousLoadings = 4;
	}
	return downloadManager_;
}

- (NSOperationQueue *) operationQueue
{
	if (!operationQueue_)
	{
		operationQueue_ = [[NSOperationQueue alloc] init];
		operationQueue_.maxConcurrentOperationCount = 1;	// TODO: tweak this with tile profiler
	}
	return operationQueue_;
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

	if (operationQueue_ && ![operationQueue_ operationCount]) 
	{
		self.operationQueue = nil;
	}
	
	self.cache = nil;
}

- (void) dealloc 
{
	self.cache				= nil;
	self.downloadManager	= nil;
	self.operationQueue		= nil;
	
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
	tileScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
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
    ZBFlipsideViewController *controller = [[[ZBFlipsideViewController alloc] initWithNibName:@"ZBFlipsideViewController" 
																					   bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
}

#pragma mark - Tiles loading

- (UIImage *) imageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature = [NSString signatureForHorIndex:horIndex verIndex:verIndex];
	
	char file[ZBFilePathLength] = { 0 };
	int fileExists = ZBCacheGetFileForSignature( self.cache, [imageSignature UTF8String], file );
	if (fileExists) 
	{ 
		NSString *filePath = [NSString stringWithCString:file encoding:NSUTF8StringEncoding];
		
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:imageSignature, kSignatureKey,
																		filePath,		kCachedPathKey, nil];
		
		NSInvocationOperation *imageOpening = [[NSInvocationOperation alloc] initWithTarget:self 
																				   selector:@selector(openImage:)
																					 object:info];
		
		[self.operationQueue addOperation:imageOpening];
		[imageOpening release];
	}
	else 
	{
		[self.downloadManager downloadImageForSignature:imageSignature];		
	}
	
	return [UIImage imageNamed:@"placeholder.png"];
}

- (void) openImage:(NSDictionary *)userInfo
{
	assert( ![NSThread isMainThread] );
	assert( userInfo );
	
	NSString *signature = [userInfo objectForKey:kSignatureKey];
	NSString *filePath =  [userInfo objectForKey:kCachedPathKey];
	
	assert( signature );
	assert( filePath );
	
	CFURLRef cfURL = CFURLCreateWithFileSystemPath( NULL, 
												   ( CFStringRef )filePath,
												   kCFURLPOSIXPathStyle, 
												   false );
	assert( cfURL );
	
	CGImageRef cgImage = NULL;
	
	CGDataProviderRef provider = CGDataProviderCreateWithURL( cfURL );
	if (provider)
	{
		cgImage = CGImageCreateWithPNGDataProvider( provider, NULL, NO, kCGRenderingIntentDefault );
		
		CGDataProviderRelease( provider );
	}
	CFRelease( cfURL );

	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:(id)cgImage,	kImageKey,
																		signature,	kSignatureKey, nil];
	CGImageRelease(cgImage);
	
	[self performSelectorOnMainThread:@selector(imageOpeningFinished:) withObject:info waitUntilDone:NO];
}
	 
- (void) imageLoadingFinished:(NSNotification *)note
{
	NSDictionary * imageInfo = note.userInfo;

	NSString *signature = [imageInfo objectForKey:kSignatureKey];
	NSString *path		= [imageInfo objectForKey:kTmpPathKey];

	if (!path) { return; } // Image was not loaded because of cancelling or error  
	
	assert( signature );
	assert( path );

	ZBCacheSetFileForSignature(self.cache, [path UTF8String], [signature UTF8String], YES);
		
	if (!tileScrollView_) { return; }

	NSUInteger horIndex, verIndex;
	ZBGetIndexesFromSignature( signature, &horIndex, &verIndex );
	
	[self.tileScrollView reloadImageForTileAtHorIndex:horIndex verIndex:verIndex];
}

- (void) imageOpeningFinished:(NSDictionary *)userInfo
{
	assert( userInfo );
	
	CGImageRef	image =		(CGImageRef)[userInfo objectForKey:kImageKey];
	NSString *	signature =				[userInfo objectForKey:kSignatureKey];
	
	assert( signature );

		// If file is corrupted it should be deleted and a new one downloaded
	if (!image) { ZBCacheRemoveFileForSignature(self.cache, [signature UTF8String]); }
	
	NSUInteger horIndex, verIndex;
	ZBGetIndexesFromSignature( signature, &horIndex, &verIndex );
	
	[self.tileScrollView setImage:image forTileAtHorIndex:horIndex verIndex:verIndex];
}

- (void) imageNoLongerNeededForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature = [NSString signatureForHorIndex:horIndex verIndex:verIndex];
	
	[self.downloadManager cancelDownloadingImageForSignature:imageSignature];
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
