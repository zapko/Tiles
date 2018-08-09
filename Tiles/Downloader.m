//
//  Downloader.m
//  Tiles
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "Downloader.h"


@interface Downloader()

@property (assign) NSThread*			workingThread;
@property (assign) NSUInteger			numberOfProcessingItems;
@property (retain) NSMutableDictionary*	processingItems;

@end


@implementation Downloader

@synthesize delegate				= delegate_;
@synthesize workingThread			= workingThread_;
@synthesize processingItems			= processingItems_;
@synthesize numberOfProcessingItems = numberOfProcessingItems_;
	
#pragma mark - Memory management

- (void) dealloc
{
	[self stopDownloadThread];
	
	[super dealloc];
}

#pragma mark - Thread stuff

- (void) launchDownloadThread
{
	@autoreleasepool 
	{
		assert( ![NSThread isMainThread] );

		NSLog(@"Download thread started");
		
		self.processingItems = [[[NSMutableDictionary alloc] init] autorelease];
		
		self.workingThread =		 [NSThread	currentThread];
		NSRunLoop* downloadRunLoop = [NSRunLoop currentRunLoop];
			
		[downloadRunLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
		
		if (delegate_ && [delegate_ respondsToSelector:@selector(downloaderIsReady:)])
		{
			[delegate_ downloaderIsReady:self];
		}
				
		while (!downloadThreadShouldStop_ && [downloadRunLoop runMode:NSDefaultRunLoopMode 
														   beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]]);
		
		NSLog(@"Download thread ended");
	}
}

- (void) stopDownloadThread
{
	downloadThreadShouldStop_		= YES;
	
	self.workingThread				= nil;
	self.processingItems			= nil;
	self.numberOfProcessingItems	= 0;
}

#pragma mark - Items manipulations

- (void) processItem:(DownloadItem *)item
{
	@autoreleasepool 
	{
		assert( item );
		assert( ![NSThread isMainThread] );
		
		NSString *signature = item.signature;
		assert( signature );
		
		NSMutableDictionary *itemsInProgress = self.processingItems;
		
		if ([itemsInProgress objectForKey:signature]) { return; }

		[itemsInProgress setObject:item forKey:signature];
		self.numberOfProcessingItems += 1;
		
		assert( self.numberOfProcessingItems == [itemsInProgress count] );
		
		item.delegate = self;
		[item startDownload];
	}
}

- (void) cancelProcessingItemWithSignature:(NSString *)signature
{
	@autoreleasepool 
	{
		assert( signature );
		assert( ![NSThread isMainThread] );
		
		DownloadItem *item = [self.processingItems objectForKey:signature];
		
		if (item) {	[item stopDownload]; } // This call would lead to downloadFinished:
	}
}

- (void) downloadFinished:(DownloadItem *)item
{
	assert( item );
	assert( ![NSThread isMainThread] );

	NSString *signature = item.signature;
	assert( signature );
	
	NSMutableDictionary *itemsInProgress = self.processingItems;
	
	if (![itemsInProgress objectForKey:signature]) { return; }

	if (delegate_ && [delegate_ respondsToSelector:@selector(itemWasProcessed:)])
	{
		[delegate_ itemWasProcessed:item];
	}
	
	[itemsInProgress removeObjectForKey:signature];
	self.numberOfProcessingItems -= 1;
	
	assert( self.numberOfProcessingItems == [itemsInProgress count] );
}

@end
