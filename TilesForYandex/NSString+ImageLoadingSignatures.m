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
	NSString *result = [NSString stringWithString:@"http://img.artlebedev.ru/everything/brain/files/8/3/64_83BB8448-3EF0-45E1-A349-6F2C381B3B2F.jpg"];
	return result;
}

@end
