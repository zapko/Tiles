//
//  DownloadManager.m
//  Tiles
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "DownloadManager.h"
#import "DownloadItem.h"

#import "NSString+ImageLoadingSignatures.h"

NSString* const ZBNotificationDownloadComplete = @"com.zababako.tiles.downloadFinishedNotification";


@interface DownloadManager()

@property (nonatomic, retain)	NSMutableArray*	queue;
@property (nonatomic, readonly) Downloader*		downloader;

@end


@implementation DownloadManager

@synthesize queue							= queue_;
@synthesize downloader						= downloader_;
@synthesize numberOfSimultaneousLoadings	= numberOfSimultaneousLoadings_;
@synthesize networkActivityDelegate			= networkActivityDelegate_;

#pragma mark - Init and memory stuff

- (id) init
{
	self = [super init];
	if (!self) { return nil; }
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(respondToMemoryWarning) 
												 name:UIApplicationDidReceiveMemoryWarningNotification
											   object:nil];

	self.numberOfSimultaneousLoadings = 3;
		
	return self;
}

- (void) dealloc
{
	[downloader_ stopDownloadThread];
	[downloader_ release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[queue_ release];
	[super	dealloc];
}

- (void) respondToMemoryWarning
{
	assert([NSThread isMainThread]);
	
	if (queue_ && [queue_ count]) { return; }	
	if (![queue_ count]) { self.queue = nil; }
	
	if (downloader_ && downloader_.numberOfProcessingItems) { return; }	
	if (!downloader_.numberOfProcessingItems) 
	{
		[downloader_ stopDownloadThread];
		[downloader_ release];
		downloader_ = nil;
	}
}

#pragma mark - Lazy properties

- (NSMutableArray *) queue
{
	if (!queue_)
	{
		queue_ = [[NSMutableArray alloc] init];
	}
	return queue_;
}

- (Downloader *) downloader
{
	if (!downloader_)
	{
		downloader_ = [[Downloader alloc] init];
		downloader_.delegate = self;
		
		[downloader_ performSelectorInBackground:@selector(launchDownloadThread) withObject:nil];
		
		[downloader_ addObserver:self 
					  forKeyPath:@"numberOfProcessingItems" 
						 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
						 context:nil];
	}
	return downloader_;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (!networkActivityDelegate_) { return; }
	
	assert( object == downloader_ );
	assert( [keyPath isEqualToString:@"numberOfProcessingItems"] );

	NSUInteger networkActive	= [[change objectForKey:@"new"] unsignedIntegerValue];
	NSUInteger networkWasActive = [[change objectForKey:@"old"] unsignedIntegerValue];

	if (networkActive && !networkWasActive)
	{
		[networkActivityDelegate_ startsUsingNetwork];
	}
	if (!networkActive && networkWasActive)
	{
		[networkActivityDelegate_ stopsUsingNetwork];
	}
}

#pragma mark - Queue manipulation

- (void) downloadImageForSignature:(NSString *)signature
{		
	assert([NSThread isMainThread]);
	
		// Check whether this item is already in the queue
	NSMutableArray* queue = self.queue;
	NSUInteger count = [queue count];
	
	NSUInteger i = 0;
	for (; i < count; ++i)
	{
		DownloadItem * iItem = [queue objectAtIndex:i];
		if ([signature isEqualToString:iItem.signature]) { break; }
	}
	
	if (i != count) { return; } // Item is already in the queue

		// Creating an item and checking condition of the downloader
	DownloadItem* item = [[DownloadItem alloc] initWithSignature:signature];
	
	NSThread* workingThread = self.downloader.workingThread;
	BOOL downloaderIsBusy = downloader_.numberOfProcessingItems >= self.numberOfSimultaneousLoadings;
	
	if (downloaderIsBusy || !workingThread) { [queue addObject:item]; }	// If Downloader is busy we add item to the queue
	else {																// otherwise start download immediately
		[downloader_ performSelector:@selector(processItem:) 
							onThread:workingThread
						  withObject:item
					   waitUntilDone:YES];
	}
	
	[item release];
}

- (void) cancelDownloadingImageForSignature:(NSString *)signature
{
	assert([NSThread isMainThread]);

	NSMutableArray* queue = self.queue;
	NSUInteger count = [queue count];
	
	NSUInteger i = 0;
	for (; i < count; ++i)
	{
		DownloadItem * iItem = [queue objectAtIndex:i];
		if ([signature isEqualToString:iItem.signature]) { break; }
	}
	
	if (i != count) { [queue removeObjectAtIndex:i]; }
	
	NSThread *workingThread = self.downloader.workingThread;

	if (!workingThread) { return; }
	
	[downloader_ performSelector:@selector(cancelProcessingItemWithSignature:)
						onThread:workingThread
					  withObject:signature
				   waitUntilDone:YES];
}

- (void) startNextItemInQueue
{
	if (!queue_ || ![queue_ count]) { return; }

	if (self.downloader.numberOfProcessingItems >= self.numberOfSimultaneousLoadings) { return; }
	
	NSThread *workingThread = self.downloader.workingThread;

	if (!workingThread) { return; }

	DownloadItem * nextItem = [[queue_ lastObject] retain];
	[queue_ removeLastObject];
	
	[downloader_ performSelector:@selector(processItem:) 
						onThread:workingThread
					  withObject:nextItem
				   waitUntilDone:YES];
	
	[nextItem release];
}

#pragma mark - Downloader delegate

- (void) itemWasProcessed:(DownloadItem *)item
{
	if ([NSThread isMainThread])
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[item signature],				kSignatureKey, 
																			[item pathToDownloadedFile],	kTmpPathKey,	nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ZBNotificationDownloadComplete object:self userInfo:userInfo];
		
		[self startNextItemInQueue];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(itemWasProcessed:) withObject:item waitUntilDone:NO];
	}	
}

- (void) downloaderIsReady: (Downloader *)downloader
{	
	if ([NSThread isMainThread]) 
	{ 
		assert(downloader == downloader_);
		[self startNextItemInQueue]; 
	}
	else 
	{
		[self performSelectorOnMainThread:@selector(downloaderIsReady:) withObject:downloader waitUntilDone:NO];
	}
}

@end
