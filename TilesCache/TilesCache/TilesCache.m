	//
	//  TilesCache.c
	//  TilesCache
	//
	//  Created by Константин Забелин on 19.02.12.
	//  Copyright (c) 2012 Zababako. All rights reserved.
	//

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>

#include "TilesCache.h"

void ZBCacheForgeFilePathForSignature( const ZBCacheRef cache, const char *signature, char result[])
{
	strncpy( result, cache->path,	ZBFilePathLength);
	strcat ( result, "cache_");
	strcat ( result, signature );
	strcat ( result, ".");
	strcat ( result, cache->extension );
}

ZBCacheRef ZBCacheCreate( const char* pathToCache, const char* tileImageExtension )
{
	int pathLen = strlen( pathToCache );
	int extLen	= strlen( tileImageExtension );
	
	ZBCacheRef cache = malloc( sizeof( ZBCache ) );
	if (!cache) { return NULL; }
	
	cache->path = calloc( pathLen + 1, sizeof(char) );
	memset( cache->path, 0, (pathLen + 1)*sizeof(char) );
	strncpy( cache->path, pathToCache, pathLen );
	
	cache->extension = calloc( extLen + 1, sizeof(char) );
	memset( cache->extension, 0, (extLen + 1)*sizeof(char) );
	strncpy( cache->extension, tileImageExtension, extLen );
	
		// TODO: check whether the path is valid
		// TODO: check whether this directory is reachable and writable
	
	return cache;
}

void ZBCacheDelete( ZBCacheRef cache )
{
	if ( cache ) 
	{ 
		free( cache->path );
		free( cache->extension );
		free( cache ); 
	}
}

int ZBCacheSetFileForSignature( const ZBCacheRef	cache, 
								const char*			tmpFilePath, 
								const char*			signature,
								bool				deleteTmpFile)
{
		// TODO: check whether file path is valid
		// TODO: check signature for symbols forbidden for filenames
		// TODO: check whether extension of the path corrensponds to extension in cache
	FILE *tmp, *cached;
	char filePath[ZBFilePathLength];
	
	tmp = fopen( tmpFilePath, "r" );
	if (!tmp) 
	{
		fprintf(stderr, "Unable to open tmp file\n");
		return 0; 
	}
	
	ZBCacheForgeFilePathForSignature(cache, signature, filePath);
	cached = fopen( filePath, "w" );
	if (!cached) 
	{ 
		fprintf(stderr, "Unable to open destitation file\n");
		fclose(tmp);
		return 0; 
	}
	
	int charSize = sizeof( char );
	int bufSize = 1024;
	char buf[bufSize];
	int condition = 0;
	
	while (!condition) 
	{
		int numread =	fread ( buf, charSize, bufSize, tmp );
		int numwrite =	fwrite( buf, charSize, numread, cached );
		
		if ( numread != numwrite ) 
		{ 
			fprintf(stderr, "Error writing data to cache\n");
			condition = 3; 
		}
		if ( numread != bufSize) 
		{ 
			if ( !feof( tmp ))	{ condition = 2; fprintf(stderr, "Error reading data from tmp\n"); }
			else				{ condition = 1; }
		}
	}
	
	fclose( cached );
	fclose( tmp );
	
	if ( deleteTmpFile && ( condition == 1 )) { remove( tmpFilePath ); }
	
	return 1;
}

int ZBCacheGetFileForSignature( const ZBCacheRef	cache,
								const char*			signature,
								char*				result )
{
	char filePath[ZBFilePathLength];
	ZBCacheForgeFilePathForSignature( cache, signature, filePath );

	FILE* test = fopen( filePath, "r" );
	if (!test)
	{
		return 0;
	}
	fclose(test);
	
	strncpy(result, filePath, ZBFilePathLength);
	return 1;
}

int	ZBCacheClear( ZBCacheRef cache )
{
		// TODO: delete all files
	return 1;
}
