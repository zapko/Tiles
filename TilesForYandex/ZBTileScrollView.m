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

- (CALayer *)dequeueReusableTile;
- (void)	 queueReusableTile:(CALayer *)tile;

- (CALayer *)tileForHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex;

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
	
	[super setDelegate:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(respondToMemoryWarning) 
												 name:UIApplicationDidReceiveMemoryWarningNotification 
											   object:nil];
	
	return self;
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
	NSLog(@"WARNING: Your are trying to use forbidden \"delegate\" property");
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

- (NSMutableSet *)reusableQueue
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

- (void) layoutSubviews
{
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
}

- (void) setTileSize:(CGSize)tileSize
{
	if (CGSizeEqualToSize(tileSize, tileSize_)) { return; }
	
	tileSize_ = tileSize;
	
	[super setContentSize:CGSizeMake(tileSize_.width  * horTilesNum_, 
									 tileSize_.height * verTilesNum_)];
	
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

- (void) setImageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex
{
	if (horIndex >= horTilesNum_) { return; } // Bounds check
	if (verIndex >= verTilesNum_) { return; }

	CALayer * tile = [[visibleTiles_ objectAtIndex:horIndex] objectAtIndex:verIndex];

	if (IsStub(tile)) { return; }												// If tile is not visible return

	tile.contents = (id)[[dataSource_ imageForTileAtHorIndex:horIndex verIndex:verIndex] CGImage];	// else set appropriate image
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	assert(scrollView == self);
	[CATransaction setDisableActions:YES];
	
	CGRect bounds = self.bounds;
	
	NSUInteger firstHorVisibleIndex = MAX( CGRectGetMinX(bounds) / tileSize_.width  - 1, 0 );
	NSUInteger firstVerVisibleIndex = MAX( CGRectGetMinY(bounds) / tileSize_.height - 1, 0 );
	
	NSUInteger lastHorVisibleIndex	= MIN( CGRectGetMaxX(bounds) / tileSize_.width  + 1, horTilesNum_ );
	NSUInteger lastVerVisibleIndex	= MIN( CGRectGetMaxY(bounds) / tileSize_.height + 1, verTilesNum_ );
	
	for (NSUInteger i = 0; i < horTilesNum_; ++i)
	{
		NSMutableArray *column = [visibleTiles_ objectAtIndex:i];
		for (NSUInteger j = 0; j < verTilesNum_; ++j)
		{
			BOOL tileIsVisible = (((i >= firstHorVisibleIndex) && (i <= lastHorVisibleIndex)) &&
								  ((j >= firstVerVisibleIndex) && (j <= lastVerVisibleIndex)));
			
			CALayer* tileLayer = [column objectAtIndex:j];
			
			if (IsStub(tileLayer))
			{
				if (!tileIsVisible) { continue; }

				tileLayer = [self tileForHorIndex:i verIndex:j];
				if (!tileLayer) { continue; }
				
				[column replaceObjectAtIndex:j withObject:tileLayer];
				
				tileLayer.frame = CGRectMake(tileSize_.width  * i, 
											 tileSize_.height * j, 
											 tileSize_.width, 
											 tileSize_.height);
				[self.layer addSublayer:tileLayer];
			}
			else
			{
				if (tileIsVisible) { continue; }

				[self queueReusableTile:tileLayer];
				[column replaceObjectAtIndex:j withObject:[NSNull null]];
					
				[dataSource_ imageNoLongerNeededForTileAtHorIndex:i verIndex:j];
			}
		}
	}
	
	[CATransaction setDisableActions:NO];
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView
{
	assert(scrollView == self);	
}

#pragma mark Scroll delegate methods (the rest of)


@end
