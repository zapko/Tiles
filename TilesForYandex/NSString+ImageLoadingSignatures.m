//
//  NSString+ImageLoadingSignatures.m
//  TilesForYandex
//
//  Created by Константин Забелин on 18.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import "NSString+ImageLoadingSignatures.h"

@implementation NSString (TilesSignatures)

- (NSString *) URLforImageFromSignature
{
	NSArray* components = [self componentsSeparatedByString:@"_"];
	assert([components count] == 2);
	NSUInteger horIndex = [[components objectAtIndex:0] integerValue];
	NSUInteger verIndex = [[components objectAtIndex:1] integerValue];
	
	int tile = (horIndex + rand_r(&verIndex)) % 12;
	
	NSString *result = [NSString stringWithFormat:@"http://dl.dropbox.com/u/19190161/Map_png_optimized/Tile_%.2d.png", tile];
	return result;
}

@end
