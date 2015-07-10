//
//  MorphLatticeModel.h
//  MorphUs
//
//  Created by Dan Shepherd on 05/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MorphLatticeModel : NSObject

- (id)initWithScreenWidth:(unsigned int)width
             screenHeight:(unsigned int)height
                     rows:(unsigned int)rows
                     cols:(unsigned int)cols;

-(unsigned int)getVerticesCount;
-(unsigned int)getIndicesCount;
-(GLfloat*)getVertices;
-(GLushort*)getIndices;
-(GLfloat*)getTextureCoords1;
-(GLfloat*)getTextureCoords2;
-(void)freebuffers;

@end
