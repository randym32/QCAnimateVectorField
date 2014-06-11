//
//  GLVertexArray.m
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

#import "BWGLVertexArray.h"
#include "glUtil.h"
#import "glErrorLogging.h"
#import <OpenCL/opencl.h>
#import "BWGLVertexBuffer.h"

@implementation BWGLVertexArray
/** Creates a vertex array or buffer (automatically which works for the sytem
    @param cgl_ctx   The core graphics GL context
    @param logger  The object to log with
*/
+(instancetype) vertexArray:(CGLContextObj)cgl_ctx
                      logger: (id<Logging>) logger
{
    // The use of vertex array vs buffer depends on the GL version
    BWGLVertexArray* ret;
#if VERTEX_BUFFER_EN > 0
    ret = [BWGLVertexBuffer alloc];
#else
    ret = [BWGLVertexArray alloc];
#endif
    return [ret init: cgl_ctx
              logger: logger];
}


- (id)  init: (CGLContextObj) _cgl_ctx
      logger: (id<Logging>)   logger
{
    if (!(self = [self init]))
        return nil;
    
    cgl_ctx = _cgl_ctx;
	// Create a vertex array object (VAO) to cache model parameters
	glGenVertexArrays(1, &vertexArray);
	glBindVertexArray(vertexArray);
    
	LogGLErrors();
    return self;
}


- (void)dealloc
{
    GLuint index;
    GLuint bufName;
    
    if (_elements)
        free(_elements);
        
    // Bind the VAO so we can get data from it
    glBindVertexArray(vertexArray);
        
    // For every possible attribute set in the VAO
    for(index = 0; index < 16; index++)
    {
        // Get the VBO set for that attibute
        glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
            
        // If there was a VBO set...
        if(bufName)
        {
            //...delete the VBO
            glDeleteBuffers(1, &bufName);
        }
    }
        
    // Get any element array VBO set in the VAO
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
        
    // If there was a element array VBO set in the VAO
    if(bufName)
    {
        //...delete the VBO
        glDeleteBuffers(1, &bufName);
    }
        
    // Finally, delete the VAO
    glDeleteVertexArrays(1, &vertexArray);
}


/** This sets the indices (to the vertices) used in the shape
    @param type      The data type of the elements in each of the index's
    @param size      The number of elements in each index
    @param arraySize The number of bytes in the in array
    @param logger    The object to log with
    @returns 0 if the caller should not free the buffer; 1 if the caller may
 */
- (int) setElements: (GLubyte *) elements
        numElements: (unsigned) numElements
           dataType: (GLenum) type
          arraySize: (size_t) arraySize
             logger: (id<Logging>) logger
{
    _numElements = numElements;
    elementType = type;
    if (_elements) free(_elements);
    _elements = elements;
    return 0;
}


/** Create a pointer suitable for use in openCL from the positions array
    @returns null on error, pointer to the buffer, suitable for openCL
    Note: you must call gcl_free() on the pointer when done.
 */
- (void*) openCLBufferForPositions
{
    // Next, map it into fit with the
    return gcl_gl_create_ptr_from_buffer(posBufferName);
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
    // Enable the position attribute for this VAO
    glEnableVertexAttribArray(POS_ATTRIB_IDX);
    
    // Get the size of the position type so we can set the stride properly
    GLsizei posTypeSize = GLTypeSize(type);
    
    // Set up parmeters for position attribute in the VAO including,
    //  size, type, stride, and offset in the currenly bound VAO
    // This also attaches the position array in memory to the VAO
    glVertexAttribPointer(POS_ATTRIB_IDX,  // What attibute index will this array feed in the vertex shader? (also see buildProgram)
                          size,             // How many elements are there per position?
                          type,             // What is the type of this data
                          GL_FALSE,	     	// Do we want to normalize this data (0-1 range for fixed-pont types)
                          size*posTypeSize, // What is the stride (i.e. bytes between positions)?
                          positions);       // Where is the position data in memory?
	LogGLErrors();
    return 0;
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
    // Enable the normal attribute for this VAO
    glEnableVertexAttribArray(NORMAL_ATTRIB_IDX);
    
    // Get the size of the normal type so we can set the stride properly
    GLsizei normalTypeSize = GLTypeSize(type);
    
    // Set up parmeters for position attribute in the VAO including,
    //   size, type, stride, and offset in the currenly bound VAO
    // This also attaches the position VBO to the VAO
    glVertexAttribPointer(NORMAL_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
                          size,	               // How many elements are there per normal?
                          type,	               // What is the type of this data?
                          GL_FALSE,	           // Do we want to normalize this data (0-1 range for fixed-pont types)
                          size*normalTypeSize, // What is the stride (i.e. bytes between normals)?
                          normals);	           // Where is normal data in memory?
	LogGLErrors();
    return 0;
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
    // Enable the texcoord attribute for this VAO
    glEnableVertexAttribArray(TEXCOORD_ATTRIB_IDX);
        
    // Get the size of the texcoord type so we can set the stride properly
    GLsizei texcoordTypeSize = GLTypeSize(type);
        
    // Set up parmeters for texcoord attribute in the VAO including,
    //   size, type, stride, and offset in the currenly bound VAO
    // This also attaches the texcoord array in memory to the VAO
    glVertexAttribPointer(TEXCOORD_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
                              size,	// How many elements are there per texture coord?
                              type,	// What is the type of this data in the array?
                              GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-point types)
                              size*texcoordTypeSize,  // What is the stride (i.e. bytes between texcoords)?
                              coords);	              // Where is the texcoord data in memory?
	LogGLErrors();
    return 0;
}


/// This has the vertices attrached / drawn to the render buffer
- (void) draw
{
    //GL_TRIANGLES
    [self draw:GL_LINES];
}


/** This has the vertices attached / drawn to the render buffer
    @param typeOfPrimitives  This is the way that the vertices are connected to form a fragment
 */
- (void) draw:(GLenum) typeOfPrimitives
{
	// Bind our vertex array object
	glBindVertexArray(vertexArray);
    glDrawElements(typeOfPrimitives, _numElements, elementType, _elements);
}
@end
