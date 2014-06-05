//
//  GLVertexBuffer.m
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
//
//

#include "glUtil.h"
#import "BWGLVertexBuffer.h"
#import "glErrorLogging.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation BWGLVertexBuffer
{
    size_t vsize;
    void const* vdata;
}


- (int)  setPositions: (GLubyte const*) positions
                 type: (GLenum) type
                 size: (GLuint) size
            arraySize: (size_t) arraySize
               logger: (id<Logging>) logger
{
    // Create a vertex buffer object (VBO) to store positions
    glGenBuffers(1, &posBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    
    // Allocate and load position data into the VBO
    glBufferData(GL_ARRAY_BUFFER, arraySize, positions, GL_DYNAMIC_DRAW);// GL_STATIC_DRAW);
    
    // Enable the position attribute for this VAO
    glEnableVertexAttribArray(POS_ATTRIB_IDX);
    
    // Get the size of the position type so we can set the stride properly
    GLsizei posTypeSize = GLTypeSize(type);
    vsize = size*posTypeSize;
    vdata = positions;
    
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


- (int)    setNormals: (GLubyte const*) normals
                 type: (GLenum) type
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


- (int)  setTexCoords: (GLubyte const*) coords
                 type: (GLenum) type
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

    
- (int)  setElements: (GLubyte *) elements
         numElements: (unsigned) numElements
                type: (GLenum) type
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


- (void) draw
{
	// Bind our vertex array object
	glBindVertexArray(vertexArray);
    //rcm
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    //Update vertex buffer data
    glBufferSubData( GL_ARRAY_BUFFER, 0, vsize, vdata );
#if 0
    glVertexAttribPointer(POS_ATTRIB_IDX, 2, GL_FLOAT, GL_FALSE,
                          sizeof(vertexStruct), (void *)offsetof(vertexStruct, position));
    glVertexAttribPointer(POS_ATTRIB_IDX,		// What attibute index will this array feed in the vertex shader (see buildProgram)
                          size,	                // How many elements are there per position?
                          type,	                // What is the type of this data?
                          GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
                          size*posTypeSize,     // What is the stride (i.e. bytes between positions)?
                          BUFFER_OFFSET(0));	// What is the offset in the VBO to the position data?
#endif
//	LogGLErrors();
    glEnableVertexAttribArray(POS_ATTRIB_IDX);

    glDrawElements(GL_TRIANGLES, _numElements, elementType, 0);
}

@end
