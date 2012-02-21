//
//  DownloadItem.h
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadItem;


@protocol DownloadItemDelegate <NSObject>

@required
- (void) downloadFinished:(DownloadItem *)sender;

@end


@interface DownloadItem : NSObject <NSURLConnectionDelegate>

@property (nonatomic, assign)	id<DownloadItemDelegate>	delegate;
@property (nonatomic, readonly) BOOL						isReady;
@property (nonatomic, readonly) NSString*					url;
@property (nonatomic, copy)		NSString*					signature;

- (id)			initWithSignature:(NSString *)signature;
- (void)		startDownload;
- (void)		stopDownload;
- (NSString *)	pathToDownloadedFile;

@end
