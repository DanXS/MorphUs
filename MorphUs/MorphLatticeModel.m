//
//  MorphLatticeModel.m
//  MorphUs
//
//  Created by Dan Shepherd on 05/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import "MorphLatticeModel.h"

@interface MorphLatticeModel()
{
    unsigned int _screenWidth;
    unsigned int _screenHeight;
    unsigned int _latticeWidth;
    unsigned int _latticeHeight;
    
    GLfloat *_latticeVertices;
    GLfloat *_latticeTexCoords1;
    GLfloat *_latticeTexCoords2;
    GLushort *_latticeIndices;
}
@end

@implementation MorphLatticeModel

- (id)initWithScreenWidth:(unsigned int)width
             screenHeight:(unsigned int)height
                     rows:(unsigned int)rows
                     cols:(unsigned int)cols
{
    self = [super init];
    if(self)
    {
        _screenWidth = width;
        _screenHeight = height;
        // Aim for rows*cols square lattice
        float meshFactorW = (float)_screenWidth/(float)cols;
        float meshFactorH = (float)_screenHeight/(float)rows;
        _latticeWidth = (int)(((float)_screenWidth)/ meshFactorW);
        _latticeHeight = (int)(((float)_screenHeight)/ meshFactorH);
        // Don't allow odd numbers of rows/cols in lattice
        if(_latticeWidth % 2 == 1)
            _latticeWidth += 1;
        if(_latticeHeight % 2 == 1)
            _latticeHeight += 1;
        _latticeVertices = malloc([self getVerticesCount]*sizeof(GLfloat));
        _latticeIndices = malloc([self getIndicesCount]*sizeof(GLushort));
        _latticeTexCoords1 = malloc([self getVerticesCount]*sizeof(GLfloat));
        _latticeTexCoords2 = malloc([self getVerticesCount]*sizeof(GLfloat));
        [self initVertices];
        [self initTextureCoords];
        [self initIndices];
    }
    return self;
}

-(void)initVertices
{
    ptrdiff_t index = 0;
    for (ptrdiff_t j = 0; j<_latticeHeight; j++) {
        for (ptrdiff_t i = 0; i<_latticeWidth; i++) {
            _latticeVertices[index++] = -1.0 + 2.0 * ((float)i / ((float)_latticeWidth-1));
            _latticeVertices[index++] = -1.0 + 2.0 * ((float)j / ((float)_latticeHeight-1));
        }
    }
}

-(void)initTextureCoords
{
    ptrdiff_t index = 0;
    for (ptrdiff_t j = 0; j<_latticeHeight; j++) {
        for (ptrdiff_t i = 0; i<_latticeWidth; i++) {
            _latticeTexCoords1[index] = (float)i / ((float)_latticeWidth-1);
            _latticeTexCoords2[index++] = (float)i / ((float)_latticeWidth-1);
            _latticeTexCoords1[index] = 1.0-((float)j / ((float)_latticeHeight-1));
            _latticeTexCoords2[index++] = 1.0-((float)j / ((float)_latticeHeight-1));
        }
    }
}

-(void)initIndices
{
    ptrdiff_t index = 0;
    for (ptrdiff_t j= 0; j < _latticeHeight-1; j++) {
        if (j % 2 == 0) { // even rows
            for (ptrdiff_t i = 0; i < _latticeWidth; i++) {
                _latticeIndices[index++] = i + j * _latticeWidth;
                _latticeIndices[index++] = i + (j + 1) * _latticeWidth;
            }
        } else { // odd rows
            for (ptrdiff_t i=_latticeWidth-1; i > 0; i-- ) {
                _latticeIndices[index++] = i + (j + 1) * _latticeWidth;
                _latticeIndices[index++] = (i - 1) + j * _latticeWidth;
            }
        }
    }
}

-(unsigned int)getVerticesCount
{
    unsigned int vertexCount = 2*_latticeWidth*_latticeHeight;
    return vertexCount;
}

-(unsigned int)getIndicesCount
{
    unsigned int indexCount = (2*_latticeWidth-1)*(_latticeHeight-1)+1;
    return indexCount;
}

-(GLfloat*)getVertices
{
    return _latticeVertices;
}

-(GLushort*)getIndices
{
    return _latticeIndices;
}

-(GLfloat*)getTextureCoords1
{
    return _latticeTexCoords1;
}

-(GLfloat*)getTextureCoords2
{
    return _latticeTexCoords2;
}

-(void)freebuffers
{
    if(_latticeVertices != NULL) {
        free(_latticeVertices);
        _latticeVertices = NULL;
    }
    if(_latticeIndices != NULL) {
        free(_latticeIndices);
        _latticeIndices = NULL;
    }
    if(_latticeTexCoords1 != NULL) {
        free(_latticeTexCoords1);
        _latticeTexCoords1 = NULL;
    }
    if(_latticeTexCoords2 != NULL) {
        free(_latticeTexCoords2);
        _latticeTexCoords2 = NULL;
    }
}

@end
