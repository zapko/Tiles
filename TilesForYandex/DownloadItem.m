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

@synthesize isReady   = isReady_;
@synthesize url		  = url_;
@synthesize signature = signature_;

- (id) initWithURL:(NSString *)url
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

- (void) startDownload
{
		// TODO: shedule connection on current loop
	[self performSelector:@selector(downloadFinished) withObject:nil afterDelay:0.5];
}

- (NSString *) pathToDownloadedFile
{
		// TODO: return path of saved file
	return (isReady_ ? [[NSBundle mainBundle] pathForResource:@"tile" ofType:@"png"] : nil);
}

	// Test part
- (void) downloadFinished
{
	if (delegate_ && [delegate_ respondsToSelector:@selector(downloadFinished:)])
	{
		isReady_ = YES;
		[delegate_ downloadFinished:self];
	}
}


@end
