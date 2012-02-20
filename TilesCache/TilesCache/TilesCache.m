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
#include <ctype.h>

#include "TilesCache.h"

void ZBCacheForgeFilePathForSignature( const ZBCacheRef cache, const char *signature, char result[] )
{
	if (( !cache ) || ( !signature ) || ( !result )) 
	{ 
		fprintf( stderr, "Invalid argument to forge file path for signture\n" );
		return; 
	}
	
		// Making appropriate filename from signature
	int signatureLen = strlen(signature);
	
	char filename[signatureLen + 1];
	for (int i = 0; i < signatureLen; ++i)
	{
		if ( isalnum( signature[i] )) {
			filename[i] = signature[i];
		}
		else {
			filename[i] = '_';
		}
	}
	
		// Forging file path
	strncpy( result, cache->path,	ZBFilePathLength);
	strcat ( result, filename );
	strcat ( result, ".");
	strcat ( result, cache->extension );
}

ZBCacheRef ZBCacheCreate( const char* pathToCache, const char* tileImageExtension )
{
	if (( !pathToCache ) || ( !tileImageExtension )) 
	{ 
		fprintf( stderr, "Invalid argument to create cache\n" );
		return NULL; 
	}
	
		// Checking whether cache directory is valid and writable
	int pathLen = strlen( pathToCache );
	char probePath[pathLen + 5]; // 4 - test 1 - \0
	strcat( probePath, "test" );

	FILE *probe = fopen( probePath, "wb" );
	if ( !probe ) {
		fprintf(stderr, "Failed to write a probe file into cache directory. Cache was not created\n");
		return NULL;
	}
	fclose( probe );
	remove( probePath );
		
		// Allocating main struct
	ZBCacheRef cache = malloc( sizeof( ZBCache ));
	if ( !cache ) { return NULL; }
	
	int charSize = sizeof( char );
	
		// Allocating path string
	cache->path = calloc( pathLen + 1, charSize );
	if ( !cache->path ) 
	{
		free( cache );
		return NULL;
	}
	memset( cache->path, 0, ( pathLen + 1 ) * charSize );
	strncpy( cache->path, pathToCache, pathLen );
	
		// Allocating extension string
	int extLen	= strlen( tileImageExtension );
	
	cache->extension = calloc( extLen + 1, charSize );
	if ( !cache->extension ) 
	{
		free( cache->path );
		free( cache );
		return NULL;
	}
	memset( cache->extension, 0, ( extLen + 1 ) * charSize );
	strncpy( cache->extension, tileImageExtension, extLen );
	
	return cache;
}

void ZBCacheDelete( ZBCacheRef cache )
{
	if ( !cache ) { return; }

	free( cache->extension );
	free( cache->path );
	free( cache ); 
}

int ZBCacheSetFileForSignature( const ZBCacheRef	cache, 
								const char*			tmpFilePath, 
								const char*			signature,
								bool				deleteTmpFile )
{
	if (( !cache ) || ( !tmpFilePath ) || ( !signature )) 
	{ 
		fprintf( stderr, "Invalid argument to set file for signature\n" );
		return 0; 
	}
	
		// Checking whether extension of the tmp file fits the extension of the cache object 
	char* tmpExtension = strrchr( tmpFilePath, '.' );
	int caseDif = tmpExtension ? strcasecmp( tmpExtension, cache->extension ) : 0;
	if ( caseDif || !tmpExtension ) 
	{
		fprintf(stderr, "Cache extension doesn't fit tmp file extension\n");
		return 0;
	}
	
		// Reading data from tmp file to file in cache directory
	FILE *tmp, *cached;
		
	tmp = fopen( tmpFilePath, "rb" );
	if ( !tmp ) 
	{
		fprintf(stderr, "Unable to open tmp file\n");
		return 0; 
	}
	
	char cachedPath[ZBFilePathLength];
	ZBCacheForgeFilePathForSignature( cache, signature, cachedPath );

	cached = fopen( cachedPath, "wb" );
	if ( !cached ) 
	{ 
		fprintf( stderr, "Unable to open destitation file\n" );
		fclose( tmp );
		return 0; 
	}
	
	int condition = 0;
	int charSize  = sizeof( char );
	int bufSize	  = 1024;
	char buf[bufSize];
	
	while ( !condition ) 
	{
		int numread =	fread ( buf, charSize, bufSize, tmp );
		int numwrite =	fwrite( buf, charSize, numread, cached );
		
		if ( numread != bufSize) 
		{ 
			if ( feof( tmp )) { condition = 1; }
			else			  { condition = 2; fprintf( stderr, "Error reading data from tmp\n" ); }
		}
		if ( numread != numwrite ) 
		{ 
			fprintf( stderr, "Error writing data to cache\n" );
			condition = 3; 
		}
	}
	
	fclose( cached );
	fclose( tmp );
	
		// Delete tmp file if it is needed
	if ( deleteTmpFile && ( condition == 1 )) { remove( tmpFilePath ); }
	
	return 1;
}

void ZBCacheRemoveFileForSignature ( const ZBCacheRef	cache,
									 const char*		signature)
{
	if (( !cache ) || ( !signature )) 
	{ 
		fprintf( stderr, "Invalid argument to remove file for signature\n" );
		return; 
	}
	
	char filePath[ZBFilePathLength];
	ZBCacheForgeFilePathForSignature( cache, signature, filePath );
	remove( filePath );
}


int ZBCacheGetFileForSignature( const ZBCacheRef	cache,
								const char*			signature,
								char*				result )
{
	if (( !cache ) || ( !signature ) || ( !result )) 
	{ 
		fprintf( stderr, "Invalid argument to get file for signature\n" );
		return; 
	}
	
	char filePath[ZBFilePathLength];
	ZBCacheForgeFilePathForSignature( cache, signature, filePath );

	FILE* test = fopen( filePath, "rb" ); // Determine whether file with this name exists and readable
	if ( !test ) { return 0; }
	fclose( test );
	
	strncpy( result, filePath, ZBFilePathLength );
	return 1;
}
