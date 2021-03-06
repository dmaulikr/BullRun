//
//  McDowell.h
//  Bull Run
//
//  Created by Dave Townsend on 5/8/13.
//  Copyright (c) 2013 Dave Townsend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BattleAt.h"
#import "BullRun.h"
#import "HexMap.h"

/** The possible types of roles which the strategy module might assign. */
typedef enum  {
    BRAIUSAUnitRoleAttack, /**< unit will advance on CSA base via the attack ford */
    BRAIUSAUnitRoleFlank,  /**< unit will advance on CSA base via the flank ford */
    BRAIUSAUnitRoleDefend  /**< unit will respond to CSA advances */
} BRAIUSAUnitRole;


/** USA AI */
@interface McDowell : NSObject <BATAIDelegate>

/** BATAIDelegate implementation. */
- (void)freeSetup:(BATGame*)game;

/** BATAIDelegate implementation. */
- (void)giveOrders:(BATGame*)game;

/**
 * The unit names which have already been assigned orders this turn.
 */
@property (nonatomic,strong) NSMutableSet* orderedThisTurn;

/** The ford which the attack force will work through. */
@property (nonatomic,assign) HXMHex        attackFord;

/** The ford which the flanking force will use. */
@property (nonatomic,assign) HXMHex        flankFord;

/** The USA game side. */
@property (nonatomic) BATPlayerSide side;

/**
 * The strategic role assigned to each USA unit.
 * key: (NSString)unitName
 * value: UnitRole enum value
 */
@property (nonatomic, strong) NSMutableDictionary* unitRoles;

@end
