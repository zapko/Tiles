//
//  DownloadManager.h
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Downloader.h"

extern NSString* const ZBNotificationDownloadComplete;

@protocol NetworkActivityDelegate <NSObject>

@required
- (void)startsUsingNetwork;
- (void)stopsUsingNetwork;

@end

	// This is an interface class for downloads management.
	// It operates on main thread and communicates with
	// Downloader class that is operating in background.

@interface DownloadManager : NSObject <DownloaderDelegate>

@property (nonatomic, assign) id<NetworkActivityDelegate>	networkActivityDelegate;
@property (nonatomic, assign) NSUInteger					numberOfSimultaneousLoadings;

- (void) downloadImageForSignature:				(NSString *)signature;
- (void) cancelDownloadingImageForSignature:	(NSString *)signature;

@end
