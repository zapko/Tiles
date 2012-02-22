//
//  ZBTileScrollView.h
//  TilesForYandex
//
//  Created by Константин Забелин on 15.02.12.
//  Copyright (c) 2012 Zababako. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBTileScrollView;


@protocol ZBTileScrollViewDataSource <NSObject>

@required
- (UIImage*) imageForTileAtHorIndex:				(NSUInteger)horIndex	verIndex:(NSUInteger)verIndex;
- (void)	 imageNoLongerNeededForTileAtHorIndex:	(NSUInteger)horIndex	verIndex:(NSUInteger)verIndex;

@end


	// Struct to work with indexes of visible tiles
typedef struct VisibleIndexes
{
	NSUInteger left;
	NSUInteger up;
	NSUInteger right;
	NSUInteger down;
} VisibleIndexes_t;

	
	// Tile scroll view that has a data source to ask for tile images
@interface ZBTileScrollView : UIScrollView
{
	NSArray*	visibleTiles_;
	BOOL		tilesShouldBeRelayouted_;
	
	VisibleIndexes_t prevVisibleIndexes_;
}

@property (nonatomic, assign)	id<ZBTileScrollViewDataSource>	dataSource;

@property (nonatomic, assign)	CGSize		tileSize;
@property (nonatomic, readonly) NSUInteger	horTilesNum;
@property (nonatomic, readonly) NSUInteger	verTilesNum;

																	// ( horNum x verNum ) is the size of the "map" in tiles
- (id)		initWithFrame:(CGRect)frame horizontalTilesNum:(NSUInteger)horNum verticalTilesNum:(NSUInteger)verNum;

- (void)	setImage:(CGImageRef)image forTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex; 
- (void)	reloadImageForTileAtHorIndex:				 (NSUInteger)horIndex verIndex:(NSUInteger)verIndex;
- (void)	reloadData;


@end
