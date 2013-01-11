//
//  HexMapGeometryTests.m
//  Bull Run
//
//  Created by Dave Townsend on 1/9/13.
//  Copyright (c) 2013 Dave Townsend. All rights reserved.
//

#import "HexMapGeometryTests.h"
#import "HexMapGeometry.h"

static HexMapGeometry* geometry;

@implementation HexMapGeometryTests

- (void)setUp {
    [super setUp];
    
    /*
     *     __    __    __    __    __
     *  __/  \__/V \__/X \__/Z \__/b \
     * /  \__/  \__/W \__/Y \__/a \__/
     * \__/  \__/U \__/  \__/  \__/c \
     * /  \__/T \__/  \__/  \__/  \__/
     * \__/  \__/  \__/  \__/  \__/d \
     * /  \__/H \__/  \__/  \__/  \__/
     * \__/S \__/I \__/  \__/  \__/e \
     * /R \__/B \__/J \__/  \__/  \__/
     * \__/G \__/C \__/  \__/  \__/  \
     * /Q \__/A \__/K \__/  \__/  \__/
     * \__/F \__/D \__/  \__/  \__/  \
     * /P \__/E \__/L \__/  \__/  \__/
     * \__/O \__/M \__/  \__/  \__/  \
     * /  \__/N \__/  \__/  \__/  \__/
     * \__/  \__/  \__/  \__/  \__/  \
     *    \__/  \__/  \__/  \__/  \__/
     *
     * (Yes, this was tedious to type up, but a picture is worth a thousand words, right?
     */
    geometry = [[HexMapGeometry alloc] initWithLongGrain:NO firstColumnIsLong:NO numRows:7 numColumns:10];
}

- (void)testLegal {
    // Obviouly wrong, as both coordinates are illegal
    STAssertFalse( [geometry legal:HexMake(-1, -1)], nil );
    STAssertFalse( [geometry legal:HexMake(10, 10)], nil );
    
    // Obviously wrong as one coordinate is illegal
    STAssertFalse( [geometry legal:HexMake(-1,  4)], nil );
    STAssertFalse( [geometry legal:HexMake( 4, -1)], nil );
    STAssertFalse( [geometry legal:HexMake(10,  4)], nil );
    STAssertFalse( [geometry legal:HexMake( 4, 10)], nil );
    
    // Check the top, bottom, and one past the bottom of the first column
    STAssertTrue(  [geometry legal:HexMake( 0,  0)], nil );
    STAssertTrue(  [geometry legal:HexMake( 0,  6)], nil );
    STAssertFalse( [geometry legal:HexMake( 0,  7)], nil );  // would be true if firstColumnIsLong:YES
    
    // Check the extra row and one past the extra row at the bottom of the second column
    STAssertTrue(  [geometry legal:HexMake( 1,  6)], nil );
    STAssertTrue(  [geometry legal:HexMake( 1,  7)], nil );  // because firstColumnIsLong:NO, so second column is long
    STAssertFalse( [geometry legal:HexMake( 1,  8)], nil );
    
    // Check the top, bottom, and one past the bottom of the penultimate column
    STAssertTrue(  [geometry legal:HexMake( 8,  0)], nil );
    STAssertTrue(  [geometry legal:HexMake( 8,  6)], nil );
    STAssertFalse( [geometry legal:HexMake( 8,  7)], nil );  // would be true if firstColumnIsLong:YES
    
    // Check the top and bottom of the last column
    STAssertTrue(  [geometry legal:HexMake( 9,  0)], nil );
    STAssertTrue(  [geometry legal:HexMake( 9,  7)], nil );
    STAssertFalse( [geometry legal:HexMake( 9,  8)], nil );
}

- (void)testDistance {
    Hex hA = HexMake(2, 4); Hex hB = HexMake(2, 3); Hex hC = HexMake(3, 4); Hex hD = HexMake(3, 5);
    Hex hE = HexMake(2, 5); Hex hF = HexMake(1, 5); Hex hG = HexMake(1, 4); Hex hH = HexMake(2, 2);
    Hex hI = HexMake(3, 3); Hex hJ = HexMake(4, 3); Hex hK = HexMake(4, 4); Hex hL = HexMake(4, 5);
    Hex hM = HexMake(3, 6); Hex hN = HexMake(2, 6); Hex hO = HexMake(1, 6); Hex hP = HexMake(0, 5);
    Hex hQ = HexMake(0, 4); Hex hR = HexMake(0, 3); Hex hS = HexMake(1, 3); Hex hT = HexMake(2, 1);
    Hex hU = HexMake(3, 1); Hex hV = HexMake(3, 0); Hex hW = HexMake(4, 0); Hex hX = HexMake(5, 0);
    Hex hY = HexMake(6, 0); Hex hZ = HexMake(7, 0); Hex ha = HexMake(8, 0); Hex hb = HexMake(9, 0);
    Hex hc = HexMake(9, 1); Hex hd = HexMake(9, 2); Hex he = HexMake(9, 3);
    
    STAssertEquals([geometry distanceFrom:hA to:hA], 0, nil);
    
    STAssertEquals([geometry distanceFrom:hA to:hB], 1, nil);
    STAssertEquals([geometry distanceFrom:hA to:hC], 1, nil);
    STAssertEquals([geometry distanceFrom:hA to:hD], 1, nil);
    STAssertEquals([geometry distanceFrom:hA to:hE], 1, nil);
    STAssertEquals([geometry distanceFrom:hA to:hF], 1, nil);
    STAssertEquals([geometry distanceFrom:hA to:hG], 1, nil);
    
    STAssertEquals([geometry distanceFrom:hC to:hJ], 1, nil);
    
    STAssertEquals([geometry distanceFrom:hA to:hH], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hI], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hJ], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hK], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hL], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hM], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hN], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hO], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hP], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hQ], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hR], 2, nil);
    STAssertEquals([geometry distanceFrom:hA to:hS], 2, nil);
    
    STAssertEquals([geometry distanceFrom:hA to:hT], 3, nil);
    STAssertEquals([geometry distanceFrom:hA to:hU], 4, nil);
    STAssertEquals([geometry distanceFrom:hA to:hV], 5, nil);
    STAssertEquals([geometry distanceFrom:hA to:hW], 5, nil);
    STAssertEquals([geometry distanceFrom:hA to:hX], 6, nil);
    STAssertEquals([geometry distanceFrom:hA to:hY], 6, nil);
    STAssertEquals([geometry distanceFrom:hA to:hZ], 7, nil);
    STAssertEquals([geometry distanceFrom:hA to:ha], 7, nil);
    STAssertEquals([geometry distanceFrom:hA to:hb], 8, nil);
    STAssertEquals([geometry distanceFrom:hA to:hc], 7, nil);
    STAssertEquals([geometry distanceFrom:hA to:hd], 7, nil);
    STAssertEquals([geometry distanceFrom:hA to:he], 7, nil);
}

@end
