//
//  BAGame.h
//  Bull Run
//
//  Created by Dave Townsend on 1/10/13.
//  Copyright (c) 2013 Dave Townsend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAGameObserving.h"
#import "BAOrderOfBattle.h"
#import "BullRun.h"
#import "HMMap.h"

@class BAUnit;

@interface BAGame : NSObject

@property (nonatomic)                   PlayerSide       userSide;
@property (nonatomic, strong, readonly) HMMap*           board;
@property (nonatomic, strong, readonly) BAOrderOfBattle* oob;
@property (nonatomic, strong, readonly) NSMutableArray*  observers;
@property (nonatomic)                   int              turn;

- (void)hackUserSide:(PlayerSide)newSide;

- (void)addObserver:(id<BAGameObserving>) observer;
- (void)doSighting:(PlayerSide)side;
- (void)processTurn;
- (BAUnit*)unitInHex:(HMHex)hex;

@end

// The single, publicly available global instance.
extern BAGame* game;

