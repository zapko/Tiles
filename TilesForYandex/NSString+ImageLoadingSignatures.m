//
//  NSString+ImageLoadingSignatures.m
//  TilesForYandex
//
//  Created by Константин Забелин on 18.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "NSString+ImageLoadingSignatures.h"

NSString* const ZBTileImageExtension = @"png";

@implementation NSString (TilesSignatures)

- (NSString *) URLforImageFromSignature
{
		// We hardly expect the string to conform to signature form "hhhhsvvvv", where
		// 'h' and 'v' are horisontal and vertical integer indexes and 's' is a separator
	NSInteger horIndex = [[self substringToIndex:4]		integerValue];
	NSInteger verIndex = [[self substringFromIndex:5]	integerValue];
	
	int tile = (horIndex + rand_r((unsigned *)&verIndex)) % 12;
	
	NSString *ext = ZBTileImageExtension;
	
	NSString *result = [NSString stringWithFormat:@"http://dl.dropbox.com/u/19190161/Map_%@_optimized/Tile_%.2d.%@", ext, tile, ext];
	return result;
}

@end
