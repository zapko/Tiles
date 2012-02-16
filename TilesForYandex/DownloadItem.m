//
//  DownloadItem.m
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "DownloadItem.h"

@implementation DownloadItem

@synthesize delegate = delegate_;

@synthesize url		  = url_;
@synthesize signature = signature_;

- (id)initWithURL:(NSString *)url
{
	self = [super init];
	if (!self) { return nil; }
	
	url_ = [url copy];
		// TODO: create NSURLConnection and InputSource for tmp file
	
	return self;
}

- (void) dealloc
{
	[url_		release];
	[signature_ release];
	
	[super dealloc];
}

- (void)startDownload
{
		// TODO: shedule connection on current loop
}

@end
