//
//  Downloader.m
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "Downloader.h"

@implementation Downloader

@synthesize delegate = delegate_;

@synthesize workingThread	= workingThread_;
@synthesize downloadingItem	= downloadingItem_;

- (void)launchDownloadThread
{
	assert( ![NSThread isMainThread] );
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSRunLoop* downloadRunLoop = [NSRunLoop currentRunLoop];
	self.workingThread =		 [NSThread	currentThread];
		
	[downloadRunLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
		
	while (!downloadThreadShouldStop_ && [downloadRunLoop runMode:NSDefaultRunLoopMode 
													  beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]]);
	
	[pool release];
}

- (void)stopDownloadThread
{
	downloadThreadShouldStop_ = YES;
}

- (void)processItem:(DownloadItem *)item
{
	assert( ![NSThread isMainThread] );
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	[downloadingItem_ release];
	
	downloadingItem_ = item;
	[downloadingItem_ retain];
	
	downloadingItem_.delegate = self;
	[downloadingItem_ startDownload];
	
	[pool release];
}

- (void)downloadFinished:(DownloadItem *)sender
{
	assert( sender == downloadingItem_ );
	
	if (delegate_ && [delegate_ respondsToSelector:@selector(itemWasProcessed:)])
	{
		[delegate_ itemWasProcessed:downloadingItem_];
	}
	[downloadingItem_ autorelease];
	downloadingItem_ = nil;
}

@end
