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

@property (nonatomic, retain)	NSURLConnection *	connection;
@property (nonatomic, copy)		NSString *			path;
@property (nonatomic, retain)	NSOutputStream *	stream;

@end


@implementation DownloadItem

@synthesize delegate = delegate_;

@synthesize isReady   = isReady_;
@synthesize url		  = url_;
@synthesize signature = signature_;

@synthesize connection	= connection_;
@synthesize path		= path_;
@synthesize stream		= stream_;

#pragma mark - Init and dealloc

- (id) initWithSignature:(NSString *)signature
{
	self = [super init];
	if (!self) { return nil; }
	
	signature_ = [signature copy];
	
	url_ = [signature URLforImageFromSignature];

		// TODO: possible collisions should be avoided
	self.path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.signature];
	
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
	
	connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	assert( connection_ );
	
	self.stream = [NSOutputStream outputStreamToFileAtPath:self.path append:NO];
	[self.stream open];
}

- (void) stopDownload
{
	if (self.connection) 
	{
		if (delegate_ && [delegate_ respondsToSelector:@selector(downloadFinished:)])
		{
			[delegate_ downloadFinished:self];
		}
		
		[self.connection cancel];
		self.connection = nil;
	}
	
	if (self.stream)
	{
		[self.stream close];
		self.stream = nil;
	}
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
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	assert( ![NSThread isMainThread] );
    assert( connection == self.connection );

    NSInteger       dataLength;
    const uint8_t * dataBytes;
    NSInteger       bytesWritten;
    NSInteger       bytesWrittenSoFar;
	    
    dataLength = [data length];
    dataBytes  = [data bytes];
	
    bytesWrittenSoFar = 0;
    do 
	{
        bytesWritten = [self.stream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten == -1) 
		{
			NSLog(@"File write error");
            [self stopDownload];
            break;
        } 
		else {
            bytesWrittenSoFar += bytesWritten;
        }
    } while (bytesWrittenSoFar != dataLength);
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

	isReady_ = YES;
	
	[self stopDownload];
}


@end
