//
//  Downloader.h
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"

	// Downloader runs in his own background thread
	// and schedules DownloadItems on it's run loop.

@protocol DownloaderDelegate <NSObject>

- (void)downloaderIsReady;
- (void)itemWasProcessed:(DownloadItem *)item;

@end

@interface Downloader : NSObject <DownloadItemDelegate>
{
	BOOL downloadThreadShouldStop_;
}

@property (nonatomic, assign)	id<DownloaderDelegate> delegate;

@property (assign, readonly) NSThread*		workingThread;
@property (assign, readonly) NSUInteger		numberOfProcessingItems;

- (void) processItem:(DownloadItem *)item;

- (void) launchDownloadThread; // Should be called in background
- (void) stopDownloadThread;   // Can be called from anywhere

@end
