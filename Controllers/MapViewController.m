//
//  MapViewController.m
//  Bull Run
//
//  Created by Dave Townsend on 12/24/12.
//  Copyright (c) 2012 Dave Townsend. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BR1AppDelegate.h" // TODO: remove/rename, can't use BR
#import "DPTSysUtil.h"
#import "HexMap.h"
#import "GameOptionsViewController.h"
#import "InfoBarView.h"
#import "MapView.h"
#import "MapViewController.h"
#import "MenuController.h"
#import "UnitView.h"

#pragma mark - Private Methods

@implementation MapViewController (Private)

- (MapView*)getMapView {
    return (MapView*)[self view];
}

@end

@implementation MapViewController

#pragma mark - Class Utilities

+ (CATransform3D)getRotationTransformForDirection:(int)dir {
    CGFloat angle = DEGREES_TO_RADIANS(dir * 60.0f);
    return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

+ (CGSize)getShadowOffsetForDirection:(int)dir {
    CGSize offset = CGSizeMake(3.0f, 3.0f);

    CGFloat angle = DEGREES_TO_RADIANS(dir * 60.0f);

    CGFloat x = offset.height * sinf(angle) + offset.width * cosf(angle);
    CGFloat y = offset.height * cosf(angle) - offset.width * sinf(angle);
    
    return CGSizeMake(x, y);
}

#pragma mark - Initialization

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        _coordXformer = [[HXMCoordinateTransformer alloc]
                         initWithMap:[game board]
                              origin:CGPointMake(66, 54)
                             hexSize:CGSizeMake(51, 51)];
        _currentUnit = nil;
        
        [self setWantsFullScreenLayout:YES];
        [self setDefinesPresentationContext:YES];

        UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        [tapRecognizer setNumberOfTapsRequired:2];

        [[self view] addGestureRecognizer:tapRecognizer];
    }
    
    return self;
}

- (void)drawLayer:(CALayer*)theLayer inContext:(CGContextRef)ctx {
    DEBUG_MOVEORDERS(@"drawLayer:inContext:");
    
    if (!_currentUnit)
        return;

    UIGraphicsPushContext(ctx);

    CGContextSetLineWidth(ctx, 7.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    // Draw orders all all friendly units other than the current unit
    if (_currentUnit) {
        UIColor* color = [_currentUnit side] == kBATPlayerSide1
                            ? [UIColor colorWithRed:0.7f green:0.3f blue:0.3f alpha:0.3f]
                            : [UIColor colorWithRed:0.3f green:0.3f blue:0.7f alpha:0.3f];
        
        for (BATUnit* u in [[game oob] unitsForSide:[_currentUnit side]]) {
            if (u != _currentUnit)
                [self drawMoveOrdersForUnit:u withColor:color inContext:ctx];
        }
    }
    
    // Draw orders for current unit
    UIColor* color = [_currentUnit side] == kBATPlayerSide1
                        ? [UIColor colorWithRed:0.7f green:0.3f blue:0.3f alpha:1.0f]
                        : [UIColor colorWithRed:0.3f green:0.3f blue:0.7f alpha:1.0f];
    [self drawMoveOrdersForUnit:_currentUnit withColor:color inContext:ctx];
    
    UIGraphicsPopContext();
}

- (void)drawMoveOrdersForUnit:(BATUnit*)unit withColor:(UIColor*)color inContext:(CGContextRef)ctx {
    if (![unit hasOrders])
        return;

    BATMoveOrders* mos = [unit moveOrders];

    // Draw orders line
    CGPoint start = [[self coordXformer] hexCenterToScreen:[unit location]];
    CGContextMoveToPoint(ctx, start.x, start.y);
    
    for (int i = 0; i < [mos numHexes]; ++i) {
        CGPoint p = [[self coordXformer] hexCenterToScreen:[mos hex:i]];
        CGContextAddLineToPoint(ctx, p.x, p.y);
        DEBUG_MOVEORDERS(@"Drawing line for %@ to (%d,%d)", [unit name], (int)p.x, (int)p.y);
    }

    CGContextSetStrokeColorWithColor(ctx, [color CGColor]);
    CGContextStrokePath(ctx);

    // Draw arrowhead at end of line
    HXMHex endHex = [mos lastHex];
    HXMHex penultimateHex = [mos numHexes] == 1 ? [unit location] : [mos hex:[mos numHexes] - 2];
    int dir = [[game board] directionFrom:penultimateHex to:endHex];

    CGPoint end = [[self coordXformer] hexCenterToScreen:endHex];

    float b = 30.0f;                        // size of the sides of the equilateral triangle
    float sqrt3 = 1.73f;                    // square root of three
    float side2center = sqrt3 * b / 6.0f;   // distance from midpoint of a side to the triangle's center
    float vertex2center = sqrt3 * b / 3.0f; // distance from vertex to the triangle's center

    if (dir & 1) { // 1, 3, 5
        CGContextMoveToPoint(   ctx, end.x,          end.y + vertex2center);
        CGContextAddLineToPoint(ctx, end.x - b/2.0f, end.y - side2center);
        CGContextAddLineToPoint(ctx, end.x + b/2.0f, end.y - side2center);

    } else { // 0, 2, 4
        CGContextMoveToPoint(   ctx, end.x,          end.y - vertex2center);
        CGContextAddLineToPoint(ctx, end.x - b/2.0f, end.y + side2center);
        CGContextAddLineToPoint(ctx, end.x + b/2.0f, end.y + side2center);
    }

    // Without this blend mode, the overlap between the triangle and the movement line
    // is twice as dark when alpha < 1.0f.
    CGContextSetBlendMode(ctx, kCGBlendModeCopy);
    
    CGContextSetFillColorWithColor(ctx, [color CGColor]);
    CGContextFillPath(ctx);
}

#pragma mark - Callbacks

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (BATUnit* unit in [[game oob] units]) {
        UnitView* v = [UnitView viewForUnit:unit];
        if (![v superlayer]) {
            [[[self view] layer] addSublayer:v];
        }
    }
    
    if (!_animationList)
        [self setAnimationList:[BATAnimationList listWithCoordXFormer:_coordXformer]];

    if (!_moveOrderLayer) {
        // iOS apps always appear in portrait mode until the end of
        // application:didFinishLaunchingWithOptions:, but this occurs before
        // then.  So the rotation is off, and we have to correct it ourselves.
        CGRect bounds = [[self view] bounds];
        CGFloat tmp = bounds.size.height;
        bounds.size.height = bounds.size.width;
        bounds.size.width = tmp;
        
        _moveOrderLayer = [CALayer layer];
        [_moveOrderLayer setBounds:bounds];
        [_moveOrderLayer setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
        [_moveOrderLayer setDelegate:self];
        [_moveOrderLayer setZPosition:100.0f];
        
        [[[self view] layer] addSublayer:_moveOrderLayer];
    }
    
    if (!_infoBarView) {
        NSArray* infoBarObjects = [[NSBundle mainBundle] loadNibNamed:@"InfoBarView" owner:self options:nil];
        
        InfoBarView* v = infoBarObjects[0];
        
        CGSize vSize = [v bounds].size;
        CGSize parentViewSize = [[self view] bounds].size;
        [v setCenter:CGPointMake(parentViewSize.height - vSize.width / 2.0, vSize.height / 2.0)];

        [self setInfoBarView:v];
        
        [[self view] addSubview:v];
        
        [v showInfoForUnit:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doubleTap:(UIGestureRecognizer*)gr {
    DEBUG_MOVEORDERS(@"Double tap!");
    if (_currentUnit) {
        [[_currentUnit moveOrders] clear];
        [[self view] setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* t in touches) {
        
        CGPoint p = [t locationInView:[self view]];
        
        if (CGRectContainsPoint([[self infoBarView] frame], p)) {
            // nothing to do
            
        } else {
            HXMHex hex = [[self coordXformer] screenToHex:p];
            
            if ([[game board] isHexOnMap:hex]) {

                DEBUG_MAP(@"Hex %02d%02d, zones:%@,%@", hex.column, hex.row, [[game board] is:hex inZone:@"csa"] ? @"CSA" : @"", [[game board] is:hex inZone:@"usa"] ? @"USA" : @"");
                DEBUG_MAP(@"   Terrain %@ cost %2.0f",
                          [[game board] terrainAt:hex] ? [[[game board] terrainAt:hex] name] : @"Impassible",
                          [[game board] terrainAt:hex] ? [[[game board] terrainAt:hex] mpCost] : 0);

                _currentUnit = [game unitInHex:hex];
                [_infoBarView showInfoForUnit:_currentUnit];
                [_moveOrderLayer setNeedsDisplay];
                _givingNewOrders = NO;
            } else {
                DEBUG_MAP(@"Touch at screen (%f,%f) isn't a legal hex!", p.x, p.y);
            }
        }
    }
}

- (void) addOrdersFor:(BATUnit*)unit movingTo:(HXMHex)hex {
    // There's some complication here because the user can drag so quickly
    // in the UI that when we convert to hexes we'll end up with non-adjacent
    // hexes, which would be a Bad Thing.

    DEBUG_MOVEORDERS(@"Orders for %@: ADD %02d%02d", [unit name], hex.column, hex.row);

    HXMHex lastHex = [[unit moveOrders] isEmpty] ? [unit location]
                                                 : [[unit moveOrders] lastHex];

    while (!HXMHexEquals(lastHex, hex)) {
        int d = [[game board] directionFrom:lastHex to:hex];
        HXMHex h = [[game board] hexAdjacentTo:lastHex inDirection:d];
        [[unit moveOrders] addHex:h];
        lastHex = h;
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    if (!_currentUnit)
        return;

    for (UITouch* t in touches) {
        HXMHex h = [_coordXformer screenToHex:[t locationInView:[self view]]];
        
        // Just ignore illegal hexes
        if (![[game board] isHexOnMap:h])
            return;
            
        if (!_givingNewOrders && HXMHexEquals([_currentUnit location], h)) {

            // The user may wiggle a finger around in the unit's current hex,
            // in which case just keep showing the existing orders.
            DEBUG_MOVEORDERS(@"Orders for %@: still in same hex", [_currentUnit name]);
                
        } else { // giving and/or continuing new orders
                
            // If this is the first hex outside the unit's current location, then
            // it's time to give new orders.
            if (!_givingNewOrders) {
                [[_currentUnit moveOrders] clear];

                _givingNewOrders = YES;
            }
            
            // Account for backtracking, where h == moveOrders[-2]
            // However, moveOrders don't understand about the unit's current location,
            // so we have to handle backtracking into the original hex as a special case.
            if ([[_currentUnit moveOrders] isBacktrack:h] ||
                ([[_currentUnit moveOrders] numHexes] == 1 && HXMHexEquals([_currentUnit location], h))) {

                DEBUG_MOVEORDERS(@"Orders for %@: BACKTRACK to %02d%02d", [_currentUnit name], h.column, h.row);
                [[_currentUnit moveOrders] backtrack];
            }
            
            // Add this hex on to the end of the list, unless it it's repeat of what's already there
            else if (HXMHexEquals([[_currentUnit moveOrders] lastHex], h)) {
                
                // Don't keep putting on the same hex on the end of the queue
                    
            } else { // it's a new hex

                [self addOrdersFor:_currentUnit movingTo:h];
            }

            [_moveOrderLayer setNeedsDisplay];
        }
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    if (!_currentUnit)
        return;
    
    DEBUG_MOVEORDERS(@"Orders for %@: END", [_currentUnit name]);
    _currentUnit = nil;
    [_moveOrderLayer setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Battle@ Callbacks

- (void)sightingChangedWithNowSightedUnits:(NSSet*)sightedUnits
                         andNowHiddenUnits:(NSSet*)hiddenUnits {
    DEBUG_SIGHTING(@"Sighting changed; sighted=%@ hidden=%@", sightedUnits, hiddenUnits);
    [_animationList addItem:[BATAnimationListItemSightingChanges
                             itemSightingChangesWithNowSightedUnits:sightedUnits
                                                  andNowHiddenUnits:hiddenUnits]];
}

- (void)moveUnit:(BATUnit*)unit to:(HXMHex)hex {
    // There's no point in showing units which are hidden; from the user's
    // POV, nothing is happening while the game waits for an invisible animation
    // to play.  The sighting routines will take care of showing hidden units
    // and/or hiding visible units as needed.
    UnitView* vw = [UnitView viewForUnit:unit];
    if ([vw isHidden])
        return;

    DEBUG_MOVEMENT(@"Moving %@ to %02d%02d", [unit name], hex.column, hex.row);
    [_animationList addItem:[BATAnimationListItemMove itemMoving:unit toHex:hex]];
}

- (void)movePhaseWillBegin {
    [_animationList reset];
}

- (void)movePhaseDidEnd {
    [_animationList run:^{
        [_infoBarView updateCurrentTimeForTurn:[game turn]];
    }];
}

- (void)showAttack:(BATBattleReport*)report {
    [_animationList
     addItem:[BATAnimationListItemCombat itemWithAttacker:[report attacker]
                                                 defender:[report defender]
                                                retreatTo:[report retreatHex]
                                                advanceTo:[report advanceHex]]];
}

#pragma mark - Debugging

- (IBAction)showOpts:(id)sender {
    NSLog(@"showing opts");
    UIViewController* gameOptionsController = [[GameOptionsViewController alloc] initWithNibName:nil bundle:nil];
    [[[BR1AppDelegate app] menuController] pushController:gameOptionsController];
}

- (IBAction)playerIsUsa:(id)sender {
    NSLog(@"Now player is USA");
    [game hackUserSide:kBATPlayerSide2];
    [_animationList run:nil];
}

- (IBAction)playerIsCsa:(id)sender {
    NSLog(@"Now player is CSA");
    [game hackUserSide:kBATPlayerSide1];
    [_animationList run:nil];
}

@end
