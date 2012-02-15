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


@interface ZBTileScrollView : UIScrollView <UIScrollViewDelegate>
{
	NSArray*	visibleTiles_;
	BOOL		tilesShouldBeRelayouted_;
}

@property (nonatomic, assign)	id<ZBTileScrollViewDataSource>	dataSource;

@property (nonatomic, assign)	CGSize		tileSize;
@property (nonatomic, readonly) NSUInteger	horTilesNum;
@property (nonatomic, readonly) NSUInteger	verTilesNum;

- (id)		initWithFrame:(CGRect)frame horizontalTilesNum:(NSUInteger)horNum verticalTilesNum:(NSUInteger)verNum;

- (void)	setImageForTileAtHorIndex:(NSUInteger)horIndex verIndex:(NSUInteger)verIndex;
- (void)	reloadData;


@end
