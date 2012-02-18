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
		// TODO: Forge real url using self as signature
	NSString *result = [NSString stringWithString:@"http://dl.dropbox.com/u/19190161/tile.png"];
	return result;
}

@end
