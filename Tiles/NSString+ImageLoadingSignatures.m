//
//  NSString+ImageLoadingSignatures.m
//  Tiles
//
//  Created by Константин Забелин on 18.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "NSString+ImageLoadingSignatures.h"

NSString* const ZBTileImageExtension = @"png";

void ZBGetIndexesFromSignature( NSString *signature, NSUInteger* horIndex, NSUInteger* verIndex)
{
		// We expect the string to conform to signature form "hhhhsvvvv", where
		// 'h' and 'v' are horizontal and vertical integer indexes and 's' is a separator
	
		// TODO: add assert

	*horIndex = [[signature substringToIndex:4]	  integerValue];
	*verIndex = [[signature substringFromIndex:5] integerValue];
}

@implementation NSString (TilesSignatures)

- (NSString *) URLforImageFromSignature
{
	NSUInteger horIndex, verIndex;
	ZBGetIndexesFromSignature(self, &horIndex, &verIndex);
	
	int tile = (horIndex + rand_r((unsigned *)&verIndex)) % 12;
	
	NSString *ext = ZBTileImageExtension;
	
	NSString *result = [NSString stringWithFormat:@"http://dl.dropbox.com/u/19190161/Map_%@_optimized/Tile_%.2d.%@", ext, tile, ext];
	return result;
}

+ (NSString *) signatureForHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	return [NSString stringWithFormat:@"%.4d_%.4d", (unsigned int)horIndex, (unsigned int)verIndex];
}

@end
