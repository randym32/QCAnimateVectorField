//
//  GLVertexArray.h
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
/*
    Copyright (c) 2014, Randall Maas

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

#import <Foundation/Foundation.h>

/// I think we want this
#if (CGL_VERSION_1_3)
// Vertex Arrays are gone 3.1 and later
// Use BWGLVertexBuffer instead of BWGLVertexArray
#define VERTEX_BUFFER_EN (1)
#endif

// Indices to which we will set vertex array attibutes
enum
{
	POS_ATTRIB_IDX,
	NORMAL_ATTRIB_IDX,
	TEXCOORD_ATTRIB_IDX
};

@protocol Logging;
@interface BWGLVertexArray : NSObject
{
    /// The core graphics GL context
    CGLContextObj cgl_ctx;
    /// The GL vertex array or buffer
    GLuint vertexArray;
    unsigned _numElements;
    GLenum elementType;
    GLubyte* _elements;
    GLuint posBufferName;
}
+ (instancetype) vertexArray: (CGLContextObj) cgl_ctx
                      logger: (id<Logging>) logger;

- (void*) openCLBufferForPositions;

- (int)  setElements: (GLubyte *) elements
         numElements: (unsigned) numElements
                type: (GLenum) type
           arraySize: (size_t) arraySize
              logger: (id<Logging>) logger;


- (int)  setPositions: (GLubyte const*) positions
                 type: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger;

- (int)    setNormals: (GLubyte const*) normals
                 type: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger;

- (int)  setTexCoords: (GLubyte const*) coords
                 type: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger;

- (void) draw;
@end
