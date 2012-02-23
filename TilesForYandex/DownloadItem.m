//
//  DownloadItem.m
//  TilesForYandex
//
//  Created by Константин Забелин on 16.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "DownloadItem.h"

#import "NSString+ImageLoadingSignatures.h"

@interface DownloadItem()

@property (nonatomic, copy)		NSString		*	path;
@property (nonatomic, retain)	NSMutableData	*	data;
@property (nonatomic, retain)	NSURLConnection *	connection;

@end


@implementation DownloadItem

@synthesize delegate = delegate_;

@synthesize isReady   = isReady_;
@synthesize url		  = url_;
@synthesize signature = signature_;

@synthesize path		= path_;
@synthesize data		= data_;
@synthesize connection	= connection_;

#pragma mark - Init and dealloc

- (id) initWithSignature:(NSString *)signature
{
	self = [super init];
	if (!self) { return nil; }
	
	signature_ = [signature copy];
	
	url_ = [[signature URLforImageFromSignature] copy];

	static NSString *tmpDir = nil;
	if (!tmpDir)
	{ 
		tmpDir = [NSTemporaryDirectory() retain];
	}
	
	NSString *ext	  = ZBTileImageExtension;
	NSString *path	  = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", signature_, ext]];
	
	NSFileManager *fileManager	= [NSFileManager defaultManager];
	BOOL		   fileExists	= [fileManager fileExistsAtPath:path];

	NSUInteger i = 1;
	while (fileExists)
	{
		path		= [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%ui.%@", signature_, ++i, ext]];
		fileExists	= [fileManager fileExistsAtPath:path];
	}
	
	self.path = path;
	
	return self;
}

- (void) dealloc
{
	[self stopDownload];
	
	[url_		release];
	[signature_ release];
	[path_		release];
	
	[super dealloc];
}

#pragma mark - Methods to work with

- (void) startDownload
{
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
	assert( request );
	
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	assert( connection_ );
		
	self.data = [[[NSMutableData alloc] initWithCapacity:5*1024] autorelease]; // Should depend on the size of files that would be downloaded
}

- (void) stopDownload
{
	if (connection_) 
	{
		if (delegate_ && [delegate_ respondsToSelector:@selector(downloadFinished:)])
		{
			[delegate_ downloadFinished:self];
		}
		
		[connection_ cancel];
		[self setConnection:nil];
	}
	
	self.data = nil;
}

- (NSString *) pathToDownloadedFile
{
	return (isReady_ ? self.path : nil);
}

#pragma mark - Connection delegate

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	assert( ![NSThread isMainThread] );
    assert( connection == self.connection );

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    assert( [httpResponse isKindOfClass:[NSHTTPURLResponse class]] );
    
    if ((httpResponse.statusCode / 100) != 2) { [self stopDownload]; } 
	else {
		[self.data setLength:0];
	}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	assert( ![NSThread isMainThread] );
    assert( connection == self.connection );

	[self.data appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	assert( ![NSThread isMainThread] );
	
	NSLog(@"Loading failed because of \"%@\"", [error description]);
	
	[self stopDownload];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	assert( ![NSThread isMainThread] );

	isReady_ = [self.data writeToFile:self.path atomically:YES];
	
	[self stopDownload];
}


@end
