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
@property (retain) DownloadItem*	downloadingItem;

@end

@implementation Downloader

@synthesize delegate = delegate_;

@synthesize workingThread	= workingThread_;
@synthesize downloadingItem	= downloadingItem_;

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
}

- (void) dealloc
{
	[self stopDownloadThread];
	
	self.downloadingItem = nil;
	
	[super dealloc];
}

- (void)processItem:(DownloadItem *)item
{
	assert( ![NSThread isMainThread] );
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	NSLog(@"Downloader \"processItem\": setting downloading item to %@", item.signature);
	self.downloadingItem = item;
	
	item.delegate = self;
	[item startDownload];
	
	[pool release];
}

- (void) downloadFinished:(DownloadItem *)sender
{
	assert( ![NSThread isMainThread] );
	assert( sender == self.downloadingItem );

	NSLog(@"Downloader \"downloadFinished\": setting downloading item from %@ to nil", self.downloadingItem.signature);
	self.downloadingItem = nil;
	
	if (delegate_ && [delegate_ respondsToSelector:@selector(itemWasProcessed:)])
	{
		[delegate_ itemWasProcessed:sender];
	}
}

@end
