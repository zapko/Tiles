//
//  DownloadManager.m
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "DownloadManager.h"
#import "Downloader.h"
#import "DownloadItem.h"

@interface DownloadManager()

@property (nonatomic, retain) NSMutableArray*	queue;
@property (nonatomic, retain) Downloader*		downloader;

@end

@implementation DownloadManager

@synthesize queue	   = queue_;
@synthesize downloader = downloader_;

- (id) init
{
	self = [super init];
	if (!self) { return nil; }
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(respondToMemoryWarning) 
												 name:UIApplicationDidReceiveMemoryWarningNotification
											   object:nil];
	
	return self;
}

- (NSMutableArray *)queue
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
	}
	return downloader_;
}

- (void)setDownloader:(Downloader *)downloader
{
	if (downloader_ == downloader) { return; }
	
	[downloader_ stopDownloadThread];
	[downloader_ release];
	
	downloader_ = downloader;
	
	[downloader_ retain];
	[downloader_ performSelectorInBackground:@selector(launchDownloadThread) withObject:nil];
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
	
	if (downloader_ && downloader_.downloadingItem)	{ return; }	
	if (!downloader_.downloadingItem) { self.downloader = nil; }
}

- (void) queueLoadinImageForSignature:(NSString *)signature
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

	
		// TODO: forge url according to signature
	NSString* imageUrl = @"http://img.artlebedev.ru/everything/rozetkus-3x3/rozetkus-3x3-anon.jpg";
	
	DownloadItem* item = [[DownloadItem alloc] initWithURL:imageUrl];
	item.signature = signature;

	if (self.downloader.downloadingItem)	{ [queue addObject:item]; }	// If Downloader is busy we add item to the queue
	else {																// otherwise start download immediately
		[downloader_ processItem:item];
	}
	
	[item release];
}

- (void) dequeueLoadingImageForSignature:(NSString *)signature
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
}

- (void)itemWasProcessed:(DownloadItem *)item
{
	if ([NSThread isMainThread])
	{
			// TODO: if item was downloaded send a notification to controller to recieve
			// TODo: start downloading of next item
	}
	else
	{
		[self performSelectorOnMainThread:@selector(itemWasProcessed:) withObject:item waitUntilDone:NO];
	}	
}

@end
