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
    /// The number of elements in the element indices
    /// This is usually atleast the number of positions as it reuses the vertices
    unsigned _numElements;
    GLenum elementType;
    GLubyte* _elements;
    GLuint posBufferName;
}

/** Creates a vertex array or buffer (automatically which works for the sytem
    @param cgl_ctx   The core graphics GL context
    @param logger  The object to log with
*/
+ (instancetype) vertexArray: (CGLContextObj) cgl_ctx
                      logger: (id<Logging>) logger;


/** Create a pointer suitable for use in openCL from the positions array
    @returns null on error, pointer to the buffer, suitable for openCL
    Note: you must call gcl_free() on the pointer when done.
 */
- (void*) openCLBufferForPositions;


/** This sets the vertices used in the shape
    @param type      The data type of the elements in each of the vertex elements
    @param size      The number of elements in each vertex
    @param arraySize The number of bytes in the in array
    @param logger    The object to log with
    @returns 0 if the caller should not free the buffer; 1 if the caller may
 */
- (int)  setPositions: (GLubyte const*) positions
             dataType: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger;


/** This sets the indices (to the vertices) used in the shape
    @param type      The data type of the elements in each of the index's
    @param size      The number of elements in each index
    @param arraySize The number of bytes in the in array
    @param logger    The object to log with
    @returns 0 if the caller should not free the buffer; 1 if the caller may
 */
- (int)  setElements: (GLubyte *) elements
         numElements: (unsigned) numElements
            dataType: (GLenum) type
           arraySize: (size_t) arraySize
              logger: (id<Logging>) logger;


/** This sets the normal vectors used in the shape
    @param type      The data type of the elements in each of the normal vectors
    @param size      The number of elements in each normal vector
    @param arraySize The number of bytes in the in array
    @param logger    The object to log with
    @returns 0 if the caller should not free the buffer; 1 if the caller may
 */
- (int)    setNormals: (GLubyte const*) normals
             dataType: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger;


/** This sets the texture coordinate vectors used in the shape
    @param type      The data type of the elements in each of the texture vectors
    @param size      The number of elements in each texture vector
    @param arraySize The number of bytes in the in array
    @param logger    The object to log with
    @returns 0 if the caller should not free the buffer; 1 if the caller may
 */
- (int)  setTexCoords: (GLubyte const*) coords
                 dataType: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger;


/// This has the vertices attached / drawn to the render buffer
- (void) draw;


/** This has the vertices attached / drawn to the render buffer
    @param typeOfPrimitives  This is the way that the vertices are connected to form a fragment
 */
- (void) draw:(GLenum) typeOfPrimitives;

@end
