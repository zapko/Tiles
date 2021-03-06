//
//  ZBMainViewController.m
//  Tiles
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

@property (nonatomic, retain)	NSMutableSet	*	loadedImages;
@property (nonatomic, retain)	ZBTileScrollView*	tileScrollView;
@property (nonatomic, retain)	DownloadManager *	downloadManager;
@property (nonatomic, retain)	NSOperationQueue*	operationQueue;
@property (nonatomic, retain)	NSMutableSet	*	probableDownloads;
@property (assign)				ZBCacheRef			cache;

@end


@implementation ZBMainViewController

@synthesize loadedImages		= loadedImages_;
@synthesize tileScrollView		= tileScrollView_;
@synthesize downloadManager		= downloadManager_;
@synthesize operationQueue		= operationQueue_;
@synthesize probableDownloads	= probableDownloads_;
@synthesize cache				= cache_;

#pragma mark -
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
		operationQueue_.maxConcurrentOperationCount = 1;
	}
	return operationQueue_;
}

- (NSMutableSet *)probableDownloads
{
	if (!probableDownloads_)
	{
		probableDownloads_ = [[NSMutableSet alloc] init];
	}
	return probableDownloads_;
}

#pragma mark - Initialization and memory management

- (ZBCacheRef) createCache
{
	NSArray *cachePaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	NSString *cachePath = [NSString stringWithFormat:@"%@/", [cachePaths objectAtIndex:0]];
	ZBCacheRef cache = ZBCacheCreate( [cachePath UTF8String], [ZBTileImageExtension UTF8String] );
	assert( cache );
	return cache;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self) { return nil;}
	
	self.cache = [self createCache];
	
	return self;
}

- (void) dealloc 
{
	self.downloadManager	= nil;
	self.operationQueue		= nil;
	self.probableDownloads	= nil;
	
	[loadedImages_	 release];
	[tileScrollView_ release];
	
	ZBCacheDelete(self.cache);
	
	[super dealloc];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

	if (operationQueue_ && ![operationQueue_ operationCount]) 
	{
		self.operationQueue = nil;
	}
	
	if (probableDownloads_ && ![probableDownloads_ count])
	{
		self.probableDownloads = nil;
	}
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
												 name:ZBNotificationDownloadComplete
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
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) showInfo:(id)sender
{    
    ZBFlipsideViewController *controller = [[[ZBFlipsideViewController alloc] initWithNibName:@"ZBFlipsideViewController" 
																					   bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Tiles images providing

- (UIImage *) imageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature	= [NSString signatureForHorIndex:horIndex verIndex:verIndex];

	[self.probableDownloads addObject:imageSignature];
	
	NSInvocationOperation *askingImage = [[NSInvocationOperation alloc] initWithTarget:self 
																			  selector:@selector(askImageForFirstTime:)
																				object:imageSignature];
	[self.operationQueue addOperation:askingImage];
	[askingImage release];
	
	return [UIImage imageNamed:@"placeholder.png"];
}

- (void) askImageForFirstTime:(NSString *)signature
{																// First time we learn whether image 
	@autoreleasepool											// is already in the cache or it 
	{															// should be downloaded
		assert( ![NSThread isMainThread] );
		assert( signature );
			
		char file[ZBFilePathLength] = { 0 };
		int fileExists = ZBCacheGetFileForSignature( self.cache, [signature UTF8String], file );
		if (fileExists) 
		{	
			NSString *filePath = [NSString stringWithCString:file encoding:NSUTF8StringEncoding];

			NSDictionary *info = [self openImageForSignature:signature atPath:filePath];
			
			[self performSelectorOnMainThread:@selector(imageOpeningFinished:) 
								   withObject:info
								waitUntilDone:NO];
		}
		else 
		{		
			[self performSelectorOnMainThread:@selector(startImageLoading:) 
								   withObject:signature
								waitUntilDone:NO];		
		}
	}
}

- (void) startImageLoading:(NSString *)signature
{
	assert( signature );
	
	if (![self.probableDownloads containsObject:signature]) { return; } // It means download was canceled because image is no longer needed
	else { [self.probableDownloads removeObject:signature]; }
	
	[self.downloadManager downloadImageForSignature:signature];
}
	 
- (void) imageLoadingFinished:(NSNotification *)note
{
	if (!tileScrollView_) { return; }

	NSDictionary*	imageInfo	= note.userInfo;		
	NSString	*	path		= [imageInfo objectForKey:kTmpPathKey];

	if (!path) { return; } // Image was not loaded because of cancelling or error  

	NSInvocationOperation *askingImageAgain = [[NSInvocationOperation alloc] initWithTarget:self 
																				   selector:@selector(askImageAfterLoading:) 
																					 object:imageInfo];
	[self.operationQueue addOperation:askingImageAgain];
	[askingImageAgain release];
}

- (void) askImageAfterLoading:(NSDictionary *)userInfo
{																	// If first time image wasn't in 
	@autoreleasepool												// the cache and we downloaded it,
	{																// Now we should write it cache and open it
		assert( ![NSThread isMainThread] );
		
		NSString *	path		= [userInfo objectForKey:kTmpPathKey];
		NSString *	signature	= [userInfo objectForKey:kSignatureKey];
		assert( signature );
		assert( path );
		
		ZBCacheSetFileForSignature( self.cache, [path UTF8String], [signature UTF8String], YES );
		
		char file[ZBFilePathLength] = { 0 };
		int fileExists = ZBCacheGetFileForSignature( self.cache, [signature UTF8String], file );
		if (!fileExists) { return; }
		
		NSString *filePath = [NSString stringWithCString:file encoding:NSUTF8StringEncoding];
		
		NSDictionary *info = [self openImageForSignature:signature atPath:filePath];
		
		[self performSelectorOnMainThread:@selector(imageOpeningFinished:) withObject:info waitUntilDone:NO];
	}
}
	
- (NSDictionary *) openImageForSignature:(NSString *)signature atPath:(NSString *)filePath	// Just a support method that 
{																							// is called while asking for 
	assert( ![NSThread isMainThread] );														// image at firts time and 
																							// after downloading
	CFURLRef cfURL = CFURLCreateWithFileSystemPath( NULL, (CFStringRef)filePath, kCFURLPOSIXPathStyle, false );	
	assert( cfURL );
	
	CGImageRef cgImage = NULL;
	
	CGDataProviderRef provider = CGDataProviderCreateWithURL( cfURL );
	if (provider)
	{
		cgImage = CGImageCreateWithPNGDataProvider( provider, NULL, NO, kCGRenderingIntentDefault );
		if ( !cgImage ) { ZBCacheRemoveFileForSignature( self.cache, [signature UTF8String] ); }
	}
	CGDataProviderRelease( provider );
	CFRelease( cfURL );
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:(id)cgImage,	kImageKey,
																		signature,	kSignatureKey, nil];
	CGImageRelease( cgImage );
	
	return info;
}

- (void) imageOpeningFinished:(NSDictionary *)userInfo	// After image was opened and decoded 
{														// we can instantly set it to tile
	assert( userInfo );
	assert( [NSThread isMainThread] );
	
	CGImageRef image = (CGImageRef)[userInfo objectForKey:kImageKey];
	if (!image) { return; }

	NSString *signature = [userInfo objectForKey:kSignatureKey];	
	assert( signature );

	[self.probableDownloads removeObject:signature];
	
	NSUInteger horIndex, verIndex;
	ZBGetIndexesFromSignature( signature, &horIndex, &verIndex );
		
	[self.tileScrollView setImage:image forTileAtHorIndex:horIndex verIndex:verIndex];
}

- (void) imageNoLongerNeededForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	NSString* imageSignature = [NSString signatureForHorIndex:horIndex verIndex:verIndex];
	
	[self.probableDownloads removeObject:imageSignature];
		
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
