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

ZBCacheRef	ZBCacheCreate( const char* path, const char* tileImageExtension);
void		ZBCacheDelete( ZBCacheRef cache );

int		ZBCacheSetFileForSignature( const ZBCacheRef	cache, 
								    const char*			tmpFilePath, 
								    const char*			signature,
									bool				deleteTmpFile );

int		ZBCacheGetFileForSignature( const ZBCacheRef	cache,
								    const char*			signature,
									char*				result );

int		ZBCacheClear( ZBCacheRef cache );

void	ZBCacheForgeFilePathForSignature( const ZBCacheRef	cache, 
										  const char *		signature, 
										  char				result[]);

#endif
