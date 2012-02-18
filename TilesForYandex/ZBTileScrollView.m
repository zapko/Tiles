//
//  ZBTileScrollView.m
//  TilesForYandex
//
//  Created by Константин Забелин on 15.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZBTileScrollView.h"

#define IsStub(obj) ((NSNull *)obj == [NSNull null])

@interface ZBTileScrollView()

@property (nonatomic, retain) NSMutableSet* reusableQueue;

- (CALayer *) dequeueReusableTile;
- (void)	  queueReusableTile:(CALayer *)tile;

- (CALayer *) tileForHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex;

- (void)	  bringTilesIntoAppropriateState;

@end



@implementation ZBTileScrollView


@synthesize reusableQueue = reusableQueue_;

@synthesize dataSource = dataSource_;

@synthesize tileSize = tileSize_;
@synthesize horTilesNum = horTilesNum_, verTilesNum = verTilesNum_;

@dynamic contentSize;

#pragma mark - Initialization

- (id) init
{
	return [self initWithFrame:CGRectZero];
}

- (id) initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame horizontalTilesNum:10 verticalTilesNum:10];
}

- (id) initWithFrame:(CGRect)frame horizontalTilesNum:(NSUInteger)horNum verticalTilesNum:(NSUInteger)verNum
{
	self = [super initWithFrame:frame];
	if (!self) { return nil; }
	
	horTilesNum_ = horNum;
	verTilesNum_ = verNum;
		
	NSMutableArray *visibleTilesColumnsRow = [[NSMutableArray alloc] init];
	for (NSUInteger i = 0; i < horTilesNum_; ++i)
	{
		NSMutableArray *visibleTilesColumn = [[NSMutableArray alloc] init];
		for (NSUInteger j = 0; j < verTilesNum_; ++j)
		{
			[visibleTilesColumn addObject:[NSNull null]];
		}
		[visibleTilesColumnsRow addObject:visibleTilesColumn];
		[visibleTilesColumn release];
	}
	visibleTiles_ = [[NSArray alloc] initWithArray:visibleTilesColumnsRow];
	[visibleTilesColumnsRow release];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(respondToMemoryWarning) 
												 name:UIApplicationDidReceiveMemoryWarningNotification 
											   object:nil];
		
	return self;
}

#pragma mark Memory management

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[reusableQueue_ release];
	[visibleTiles_	release];
	
	[super dealloc];
}

- (void) respondToMemoryWarning
{
	self.reusableQueue = nil;
		//TODO: check possible ways to free memory
}

#pragma mark - Reusable tiles queue

- (NSMutableSet *) reusableQueue
{
	if (!reusableQueue_) 
	{ 
		reusableQueue_ = [[NSMutableSet alloc] init];
	}
	
	return reusableQueue_; 	
}

- (CALayer*) dequeueReusableTile
{
	CALayer* tile = [self.reusableQueue anyObject];

	if (tile) 
	{
		[[tile retain] autorelease];
		[self.reusableQueue removeObject:tile]; 
	}
	
	return tile;
}

- (void) queueReusableTile:(CALayer *)tile
{
	[self.reusableQueue addObject:tile];
	[tile removeFromSuperlayer];
}

#pragma mark Size manipulations

- (void) setFrame:(CGRect)frame
{
	BOOL sizeChanged = !CGSizeEqualToSize(frame.size, self.frame.size);

	[super setFrame:frame];
	
	if (sizeChanged) 
	{
		tilesShouldBeRelayouted_ = YES;
		[self bringTilesIntoAppropriateState]; 
	}
}

- (void) setBounds:(CGRect)bounds
{
	CGRect oldBounds = self.bounds;
	
	BOOL changed		=			 !CGRectEqualToRect(bounds,			oldBounds);
	BOOL sizeChanged	= changed && !CGSizeEqualToSize(bounds.size,	oldBounds.size);

	[super setBounds:bounds];
	
	if (changed) 
	{ 
		[self bringTilesIntoAppropriateState]; 

		if (sizeChanged) { tilesShouldBeRelayouted_ = YES; }
	}
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	if (!tilesShouldBeRelayouted_) { return; }

	CGFloat tileWidth	= tileSize_.width;
	CGFloat tileHeight	= tileSize_.height;
	
	for (NSUInteger i = 0; i < horTilesNum_; ++i)
	{
		NSArray *tilesColumn = [visibleTiles_ objectAtIndex:i];
		
		for (NSUInteger j = 0; j < verTilesNum_; ++j)
		{
			CALayer *layer = [tilesColumn objectAtIndex:j];

			if (IsStub(layer)) { continue; }

			layer.frame = CGRectMake(tileWidth*i, tileHeight*j, tileWidth, tileHeight);
		}
	}
	
	tilesShouldBeRelayouted_ = NO;
}

- (void) setTileSize:(CGSize)tileSize
{
	if (CGSizeEqualToSize(tileSize, tileSize_)) { return; }
	
	tileSize_ = tileSize;
	
	[super setContentSize:CGSizeMake(tileSize_.width  * horTilesNum_, 
									 tileSize_.height * verTilesNum_)];
	
	tilesShouldBeRelayouted_ = YES;
	[self setNeedsLayout];
}

- (void) setContentSize:(CGSize)contentSize
{
	[self setTileSize:CGSizeMake(contentSize.width	/ (CGFloat)horTilesNum_, 
								 contentSize.height / (CGFloat)verTilesNum_)];
		// This method will invoke super's implementation and setNeedsLayout if appropriate
}

#pragma mark Tile manipulation

- (CALayer *) tileForHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	if (horIndex >= horTilesNum_) { return nil; } // Bounds check
	if (verIndex >= verTilesNum_) { return nil; }
	
	CALayer * tile = [self dequeueReusableTile]; 
		
	if (!tile) { tile = [[[CALayer alloc] init] autorelease]; }
		
	tile.contents = (id)[[dataSource_ imageForTileAtHorIndex:horIndex verIndex:verIndex] CGImage];

	return tile;
}

- (void) reloadImageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	if (horIndex >= horTilesNum_) { return; } // Bounds check
	if (verIndex >= verTilesNum_) { return; }

	CALayer * tile = [[visibleTiles_ objectAtIndex:horIndex] objectAtIndex:verIndex];

	if (IsStub(tile)) { return; }												// If tile is not visible return

	tile.contents = (id)[[dataSource_ imageForTileAtHorIndex:horIndex verIndex:verIndex] CGImage];	// else set appropriate image
}

- (void) bringTilesIntoAppropriateState
{
	assert( [NSThread isMainThread] );
	[CATransaction setDisableActions:YES];
	
	CGRect bounds = self.bounds;
	
		// Determinig indexes of visible tiles
	NSUInteger firstHorVisibleIndex = MAX( CGRectGetMinX(bounds) / tileSize_.width  - 1, 0 );
	NSUInteger firstVerVisibleIndex = MAX( CGRectGetMinY(bounds) / tileSize_.height - 1, 0 );
	
	NSUInteger lastHorVisibleIndex	= MIN( CGRectGetMaxX(bounds) / tileSize_.width  + 1, horTilesNum_ );
	NSUInteger lastVerVisibleIndex	= MIN( CGRectGetMaxY(bounds) / tileSize_.height + 1, verTilesNum_ );
	
		// Going through all tiles
	for (NSUInteger i = 0; i < horTilesNum_; ++i)
	{
		NSMutableArray *column = [visibleTiles_ objectAtIndex:i];
		for (NSUInteger j = 0; j < verTilesNum_; ++j)
		{
				// If tile is visible it should be put into visibleTiles_, otherwise it should be released
			BOOL tileIsVisible = (((i >= firstHorVisibleIndex) && (i <= lastHorVisibleIndex)) &&
								  ((j >= firstVerVisibleIndex) && (j <= lastVerVisibleIndex)));
			
			CALayer* tileLayer = [column objectAtIndex:j];

			if (tileIsVisible)
			{
				if (!IsStub(tileLayer)) { continue; }
				
				tileLayer = [self tileForHorIndex:i verIndex:j];
				assert(tileLayer);
				
				[column replaceObjectAtIndex:j withObject:tileLayer];
				
				tileLayer.frame = CGRectMake(tileSize_.width  * i, 
											 tileSize_.height * j, 
											 tileSize_.width, 
											 tileSize_.height);
				[self.layer insertSublayer:tileLayer atIndex:0];
			}
			else
			{
				if (IsStub(tileLayer)) { continue; }

				[self queueReusableTile:tileLayer];
				[column replaceObjectAtIndex:j withObject:[NSNull null]];
				
				[dataSource_ imageNoLongerNeededForTileAtHorIndex:i verIndex:j];
			}
		}
	}
	
	[CATransaction setDisableActions:NO];
}

- (void)reloadData
{
	for (NSUInteger i = 0; i < horTilesNum_; ++i)
	{
		NSMutableArray *column = [visibleTiles_ objectAtIndex:i];
		for (NSUInteger j = 0; j < verTilesNum_; ++j)
		{
			CALayer *tileLayer = [column objectAtIndex:j];
			
			if (IsStub(tileLayer)) { continue; }
			
			[self queueReusableTile:tileLayer];
			[column replaceObjectAtIndex:j withObject:[NSNull null]];
		}
	}
}

@end
