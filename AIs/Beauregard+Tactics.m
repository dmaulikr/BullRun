//
//  Beauregard+Tactics.m
//  Bull Run
//
//  Created by Dave Townsend on 6/16/13.
//  Copyright (c) 2013 Dave Townsend. All rights reserved.
//

#import "Beauregard+Strategy.h"
#import "Beauregard+Tactics.h"
#import "BR1Map.h"
#import "NSArray+DPTUtil.h"

//==============================================================================
@implementation Beauregard (Private)

- (void)devalueInfluenceMap:(BATAIInfluenceMap*)imap atHex:(HXMHex)hex {
    HXMMap* map = [game board];

    [imap multiplyBy:0.25f atHex:hex];

    for (int dir = 0; dir < 6; ++dir)
        [imap multiplyBy:0.5f atHex:[map hexAdjacentTo:hex inDirection:dir]];
}

- (NSNumber*)computeAttackChanceOf:(BATUnit*)unit inDirection:(int)dir {
    HXMHex hex = [[game board] hexAdjacentTo:[unit location] inDirection:dir];
    if (![[game board] isHexOnMap:hex])
        return @(0);

    BATUnit* enemy = [game unitInHex:hex];
    if (!enemy || [enemy side] == [self side])
        return @(0);

    int val = 0;

    BRAICSATheater theater = [self computeTheaterOf:unit];
    HXMHex nearestBaseHex = [self baseHexForTheater:theater];

    // Surrounded units should consider breaking out
    if ([game unitIsSurrounded:unit])
        val += 10;

    // Should almost always try to clear a base
    if (HXMHexEquals(hex, nearestBaseHex))
        val += 60;

    // TODO: direction is not towards closest base: -10

    // hex in USA territory: -800
    if ([[game board] is:hex inZone:@"usa"] && ![[game board] is:hex inZone:@"csa"])
        val -= 800;

    // always weight to increase chance of attack when near base
    val += 2 * (10 - [[game board] distanceFrom:hex to:nearestBaseHex]);

    return @(val);
}

@end


//==============================================================================
@implementation Beauregard (Tactics)

- (void)assignAttackers {
    NSArray* csaUnits = [[game oob] unitsForSide:CSA];
    [csaUnits enumerateObjectsUsingBlock:^(BATUnit* unit, NSUInteger idx, BOOL* stop) {
        if ([unit isWrecked])
            return;

        DEBUG_AI(@"assignAttacker considering %@", [unit name]);

        NSMutableArray* attackChances = [NSMutableArray arrayWithCapacity:6];
        for (int i = 0; i < 6; ++i)
            attackChances[i] = [self computeAttackChanceOf:unit inDirection:i];

        // find max value in attackChances
        int attackDir = [attackChances dpt_max_idx];
        int attackChance = [attackChances[attackDir] intValue];

        if ([game unitIsSurrounded:unit])
            attackChance *= 2;

        // No possible attacks
        if (attackChance == 0) {
            DEBUG_AI(@"  => not attacking because no enemies adjacent");
            return;
        }

        int dieroll = random() % 100;

        if (dieroll > attackChance * 2) {
            DEBUG_AI(@"  => not attacking because dieroll %d > chance %d",
                     dieroll, attackChance);
            return;
        }

        if (dieroll < attackChance)
            [unit setMode:kBATModeCharge];

        else if (dieroll < attackChance * 1.5)
            [unit setMode:kBATModeAttack];

        else
            [unit setMode:kBATModeSkirmish];
        
        // set unit orders to hex
        [[unit moveOrders]
         addHex:[[game board] hexAdjacentTo:[unit location]
                                inDirection:attackDir]];
        DEBUG_AI(@"  => attacking dir %d in mode %d because roll %d chance %d",
                 attackDir, [unit mode], dieroll, attackChance);
    }];
}

- (BOOL)assignDefender:(BATAIInfluenceMap*)imap {
    BR1Map* map = [BR1Map map];
    HXMHexAndDistance hexd = [imap largestValue];
    if (hexd.distance < 1)
        return NO;

    NSArray* csaUnits = [self unorderedCsaUnits];
    NSArray* distances = [csaUnits dpt_map:^NSNumber*(BATUnit* unit) {
        return @([map distanceFrom:[unit location] to:hexd.hex]);
    }];
    int i = [distances dpt_min_idx];

    if (i >= 0) {
        BATUnit* unit = csaUnits[i];
        DEBUG_AI(@"assignDefender %@ to %02d%02d", [unit name], hexd.hex.column, hexd.hex.row);

        if ([map is:[unit location] inZone:@"usa"]) {
            HXMHexAndDistance fordLoc = [map closestFordTo:[unit location]];
            [self routeUnit:unit toDestination:fordLoc.hex];
        } else {
            [self routeUnit:unit toDestination:hexd.hex];
        }

        [[self orderedThisTurn] addObject:[unit name]];
        [self devalueInfluenceMap:imap atHex:hexd.hex];
    } else
        DEBUG_AI(@"assignDefender fails because no defenders are left");

    return i >= 0;
}

- (void)routeUnit:(BATUnit*)unit toDestination:(HXMHex)destination {
    HXMMap* map = [game board];
    HXMHex curHex = [unit location];

    HXMPathFinder* pf = [HXMPathFinder pathFinderOnMap:map withMinCost:4.0f];

    NSArray* path = [pf findPathFrom:curHex
                                  to:destination
                               using:^float(HXMHex from, HXMHex to) {
                                   HXMTerrainEffect* fx = [map terrainAt:to];

                                   if (!fx) // impassible
                                       return -1.0f;

                                   // TODO: ZOC/occupancy checks

                                   return [fx mpCost];
                               }];

    [[unit moveOrders] clear];

    // There's no point in planning out more than two hexes, because
    // we recalculate orders every turn and no unit moves more than
    // two hexes per turn.  Remember that the path finder returns the
    // starting hex in path[0], so the new hexes begin at path[1].
    for (int i = 1; i < 3 && i < [path count]; ++i)
        [[unit moveOrders] addHex:[path[i] hexValue]];
}

@end
