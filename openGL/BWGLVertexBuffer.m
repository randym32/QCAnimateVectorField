//
//  GLVertexBuffer.m
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

#include "glUtil.h"
#import "BWGLVertexBuffer.h"
#import "glErrorLogging.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation BWGLVertexBuffer
{
    /// The number of positions in the vertex array
    /// (The number of elements can be larger, as it may reuse vertices)
    size_t _numPositions;
}


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
               logger: (id<Logging>) logger
{
    // Create a vertex buffer object (VBO) to store positions
    glGenBuffers(1, &posBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    
    // Allocate and load position data into the VBO
    glBufferData(GL_ARRAY_BUFFER, arraySize, positions, GL_DYNAMIC_DRAW);
    
    // Enable the position attribute for this VAO
    glEnableVertexAttribArray(POS_ATTRIB_IDX);
    
    // Get the size of the position type so we can set the stride properly
    GLsizei posTypeSize = GLTypeSize(type);
    size_t elementSize = size*posTypeSize;
    _numPositions = arraySize/elementSize;
    
    // Set up parmeters for position attribute in the VAO including,
    //  size, type, stride, and offset in the currenly bound VAO
    // This also attaches the position VBO to the VAO
    glVertexAttribPointer(POS_ATTRIB_IDX,		// What attibute index will this array feed in the vertex shader (see buildProgram)
                          size,	                // How many elements are there per position?
                          type,	                // What is the type of this data?
                          GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
                          size*posTypeSize,     // What is the stride (i.e. bytes between positions)?
                          BUFFER_OFFSET(0));	// What is the offset in the VBO to the position data?
	LogGLErrors();
    // We have copied the data
    return 1;
}


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
               logger: (id<Logging>) logger
{
    GLuint normalBufferName;
    
    // Create a vertex buffer object (VBO) to store positions
    glGenBuffers(1, &normalBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, normalBufferName);
    
    // Allocate and load normal data into the VBO
    glBufferData(GL_ARRAY_BUFFER, arraySize, normals, GL_STATIC_DRAW);
    
    // Enable the normal attribute for this VAO
    glEnableVertexAttribArray(NORMAL_ATTRIB_IDX);
    
    // Get the size of the normal type so we can set the stride properly
    GLsizei normalTypeSize = GLTypeSize(type);
    
    // Set up parmeters for position attribute in the VAO including,
    //   size, type, stride, and offset in the currenly bound VAO
    // This also attaches the position VBO to the VAO
    glVertexAttribPointer(NORMAL_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
                          size,	                // How many elements are there per normal?
                          type,	                // What is the type of this data?
                          GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
                          size*normalTypeSize,  // What is the stride (i.e. bytes between normals)?
                          BUFFER_OFFSET(0));	// What is the offset in the VBO to the normal data?
	LogGLErrors();
    // We have copied the data
    return 1;
}


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
               logger: (id<Logging>) logger
{
    GLuint texcoordBufferName;
    
    // Create a VBO to store texcoords
    glGenBuffers(1, &texcoordBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, texcoordBufferName);
    
    // Allocate and load texcoord data into the VBO
    glBufferData(GL_ARRAY_BUFFER, arraySize, coords, GL_STATIC_DRAW);
    
    // Enable the texcoord attribute for this VAO
    glEnableVertexAttribArray(TEXCOORD_ATTRIB_IDX);
    
    // Get the size of the texcoord type so we can set the stride properly
    GLsizei typeSize = GLTypeSize(type);
    
    // Set up parmeters for texcoord attribute in the VAO including,
    //   size, type, stride, and offset in the currenly bound VAO
    // This also attaches the texcoord VBO to VAO
    glVertexAttribPointer(TEXCOORD_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
                          size,	// How many elements are there per texture coord?
                          type,	// What is the type of this data in the array?
                          GL_TRUE,				// Do we want to normalize this data (0-1 range for fixed-point types)
                          size*typeSize,        // What is the stride (i.e. bytes between texcoords)?
                          BUFFER_OFFSET(0));	// What is the offset in the VBO to the texcoord data?
	LogGLErrors();
    // We have copied the data
    return 1;
}

    
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
              logger: (id<Logging>) logger
{
    _numElements = numElements;
    elementType = type;

    GLuint elementBufferName;
    
    // Create a VBO to vertex array elements
    // This also attaches the element array buffer to the VAO
    glGenBuffers(1, &elementBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
    
    // Allocate and load vertex array element data into VBO
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, arraySize, elements, GL_STATIC_DRAW);
	LogGLErrors();
    return 1;
}


/** This has the vertices attached / drawn to the render buffer
    @param typeOfPrimitives  This is the way that the vertices are connected to form a fragment
 */
- (void) draw:(GLenum) typeOfPrimitives
{
	// Bind our vertex array object
	glBindVertexArray(vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    //Update vertex buffer data
    // No, don't.
    // Using this wipes out the data... and not needed when we're working with openCL linked ata bufers
//    glBufferSubData( GL_ARRAY_BUFFER, 0, elementSize*_numPositions, vdata );
    glEnableVertexAttribArray(POS_ATTRIB_IDX);

#if E_EN > 0
    glDrawElements(typeOfPrimitives, _numElements, elementType, 0);
#else
    glDrawArrays(typeOfPrimitives,0, _numPositions);
#endif
}

@end
