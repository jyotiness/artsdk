//
//  ACFavoritesRemoveActivity.h
//  ArtAPI
//
//  Created by Doug Diego on 2/13/14.
//  Copyright (c) 2014 Doug Diego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACFavoritesActivity.h"

@interface ACFavoritesRemoveActivity : UIActivity

@property(readwrite,nonatomic) FavoritesType type;

- (instancetype)initWithType:(FavoritesType)type;


@end
