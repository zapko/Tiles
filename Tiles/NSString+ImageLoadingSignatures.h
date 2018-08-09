//
//  NSString+ImageLoadingSignatures.h
//  Tiles
//
//  Created by Константин Забелин on 18.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#define kSignatureKey	@"signature"
#define kTmpPathKey		@"tmpPath"
#define kCachedPathKey	@"cachedPath"
#define kImageKey		@"imageRef"
#define kCacheKey		@"cache"

extern NSString* const ZBTileImageExtension;

void ZBGetIndexesFromSignature( NSString *signature, NSUInteger* horIndex, NSUInteger* verIndex);


@interface NSString (TilesSignatures)

+ (NSString *) signatureForHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex;
- (NSString *) URLforImageFromSignature;

@end
