	//
	//  TilesCache.h
	//  TilesCache
	//
	//  Created by Константин Забелин on 19.02.12.
	//  Copyright (c) 2012 Zababako. All rights reserved.
	//

#ifndef TilesCache_TilesCache_h
#define TilesCache_TilesCache_h

#include <stdbool.h>

#define ZBFilePathLength 256

struct ZBCache_
{
	char* path;
	char* extension;
};

typedef struct ZBCache_ ZBCache;
typedef ZBCache*		ZBCacheRef;

	// First of this functions creates cache object and assosiate it with path to 
	// directory where downloaded images will be kept and theirs extension.
	// Second one releases memory allocated for a cache object.
ZBCacheRef	ZBCacheCreate( const char* path, const char* tileImageExtension);
void		ZBCacheDelete( ZBCacheRef cache );

	
	// This function copies or moves downloaded tile image file from temprorary path to
	// path associated with the cache. Tile image is identified in cache by signature.
int		ZBCacheSetFileForSignature( const ZBCacheRef	cache, 
								    const char*			tmpFilePath, 
								    const char*			signature,
									bool				deleteTmpFile );
	
	// Here is the way to get a cached file from a tile signature if it is already
	// downloaded and cached
int		ZBCacheGetFileForSignature( const ZBCacheRef	cache,
								    const char*			signature,
									char*				result );

	// Removes cached image file from cache
void	ZBCacheRemoveFileForSignature ( const ZBCacheRef	cache,
										const char*			signature);

	// It's utility function to generate a possible filepath for a tile signature.
void	ZBCacheForgeFilePathForSignature( const ZBCacheRef	cache, 
										  const char *		signature, 
										  char				result[]);

#endif
