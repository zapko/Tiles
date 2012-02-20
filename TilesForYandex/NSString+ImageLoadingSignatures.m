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

	NSString *result = [NSString stringWithFormat:@"http://dl.dropbox.com/u/19190161/Map_jpg_low/Tile_%.2d.jpg", (horIndex + verIndex) % 8];
	return result;
}

@end
