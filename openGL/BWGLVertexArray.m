//
//  GLVertexArray.m
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
//
//

#import "BWGLVertexArray.h"
#include "glUtil.h"
#import "glErrorLogging.h"
#import <OpenCL/opencl.h>

GLuint m_characterNumElements;

@implementation BWGLVertexArray

- (id)  init: (CGLContextObj) _cgl_ctx
      logger: (id<Logging>) logger
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
        
//    LogGLErrors();
}

- (int) setElements: (GLubyte *) elements
         numElements: (unsigned) numElements
                type: (GLenum) type
           arraySize: (size_t) arraySize
             logger: (id<Logging>) logger
{
    _numElements = numElements;
    elementType = type;
    if (_elements) free(_elements);
    _elements = elements;
    return 0;
}


- (void*) openCLBufferForPositions
{
    // Next, map it into fit with the
//    CGLShareGroupObj sharegroup = CGLGetShareGroup(cgl_ctx);
//    gcl_gl_set_sharegroup(sharegroup);
    return gcl_gl_create_ptr_from_buffer(posBufferName);
}


- (int)  setPositions: (GLubyte const*) positions
                 type: (GLenum) type
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


- (int)    setNormals: (GLubyte const*) normals
                 type: (GLenum) type
                 size:(GLuint) size
            arraySize:(size_t) arraySize
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


- (int)  setTexCoords: (GLubyte const*) coords
                 type: (GLenum) type
                 size:(GLuint) size
            arraySize:(size_t) arraySize
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


- (void) draw
{
	// Bind our vertex array object
	glBindVertexArray(vertexArray);
    glDrawElements(GL_TRIANGLES, _numElements, elementType, _elements);
}
@end