//
//  Downloader.m
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "Downloader.h"

@interface Downloader()

@property (assign) NSThread*		workingThread;
@property (assign) NSUInteger		numberOfProcessingItems;

@end

@implementation Downloader

@synthesize delegate = delegate_;

@synthesize workingThread	= workingThread_;
@synthesize numberOfProcessingItems = numberOfProcessingItems_;

- (void)launchDownloadThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	assert( ![NSThread isMainThread] );

	NSLog(@"Download thread started");
	
	workingThread_ =			 [NSThread	currentThread];
	NSRunLoop* downloadRunLoop = [NSRunLoop currentRunLoop];
		
	[downloadRunLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
	
	if (delegate_ && [delegate_ respondsToSelector:@selector(downloaderIsReady)])
	{
		[delegate_ downloaderIsReady];
	}
			
	while (!downloadThreadShouldStop_ && [downloadRunLoop runMode:NSDefaultRunLoopMode 
													  beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]);
	
	NSLog(@"Download thread ended");
	
	[pool release];
}

- (void)stopDownloadThread
{
	downloadThreadShouldStop_ = YES;
	workingThread_ = nil;
	numberOfProcessingItems_ = 0;
}

- (void) dealloc
{
	[self stopDownloadThread];
		
	[super dealloc];
}

- (void)processItem:(DownloadItem *)item
{
	assert( ![NSThread isMainThread] );
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

//	NSLog(@"Downloader \"processItem\": setting downloading item to %@", item.signature);
	self.numberOfProcessingItems += 1;
	
	item.delegate = self;
	[item startDownload];
	
	[pool release];
}

- (void) downloadFinished:(DownloadItem *)sender
{
	assert( ![NSThread isMainThread] );

//	NSLog(@"Downloader \"downloadFinished\": setting downloading item from %@ to nil", self.downloadingItem.signature);
	self.numberOfProcessingItems -= 1;
	
	if (delegate_ && [delegate_ respondsToSelector:@selector(itemWasProcessed:)])
	{
		[delegate_ itemWasProcessed:sender];
	}
}

@end
