//
//  ZBTileScrollView.m
//  TilesForYandex
//
//  Created by Константин Забелин on 15.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZBTileScrollView.h"



@interface ZBTileScrollView()

@property (nonatomic, retain) NSMutableSet* reusableQueue;

- (CALayer *)dequeueReusableTile;
- (void)	 queueReusableTile:(CALayer *)tile;

@end



@implementation ZBTileScrollView


@synthesize reusableQueue = reusableQueue_;

@synthesize dataSource = dataSource_, delegate = delegate_;

@synthesize tileSize = tileSize_;
@synthesize horTilesNum = horTilesNum_, verTilesNum = verTilesNum_;

@dynamic contentSize;

#pragma mark - Initialization

- (id)init
{
	return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
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

#pragma mark Memory management

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[reusableQueue_ release];
	[visibleTiles_	release];
	
	[super dealloc];
}

- (void)respondToMemoryWarning
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

- (CALayer *)dequeueReusableTile
{
	CALayer *tile = [[self.reusableQueue anyObject] autorelease];
	[self.reusableQueue removeObject:tile];
	
	return tile;
}

- (void)queueReusableTile:(CALayer *)tile
{
	[tile retain];
	[tile removeFromSuperlayer];
	[self.reusableQueue addObject:tile];
	[tile release];
}

#pragma mark Size manipulations

- (void)layoutSubviews
{
	CGFloat tileWidth	= tileSize_.width;
	CGFloat tileHeight	= tileSize_.height;
	
	for (NSUInteger i = 0; i < horTilesNum_; ++i)
	{
		NSArray *tilesColumn = [visibleTiles_ objectAtIndex:i];
		
		for (NSUInteger j = 0; j < verTilesNum_; ++j)
		{
			CALayer *layer = [tilesColumn objectAtIndex:j];
			if ((NSNull *)layer == [NSNull null]) { continue; }

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

- (void)setContentSize:(CGSize)contentSize
{
	[self setTileSize:CGSizeMake(contentSize.width	/ (CGFloat)horTilesNum_, 
								 contentSize.height / (CGFloat)verTilesNum_)];
		// This method will invoke super's implementation and setNeedsLayout if appropriate
}

#pragma mark Tile manipulation

- (void) setImageForTileAtIndexPath:(NSIndexPath *)indexPath
{
		//TODO: check whether tile is visible
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	assert(scrollView == self);
	
	if (delegate_ && [delegate_ respondsToSelector:@selector(tileScrollViewDidScroll::)]) 
	{
		[delegate_ tileScrollViewDidScroll:self];
	}
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	assert(scrollView == self);
	
	if (delegate_ && [delegate_ respondsToSelector:@selector(tileScrollViewDidZoom:)])
	{
		[delegate_ tileScrollViewDidZoom:self];
	}
}

#pragma mark Scroll delegate methods (the rest of)


@end
