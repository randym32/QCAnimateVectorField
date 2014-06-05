//
//  GLVertexArray.h
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
//
//

#import <Foundation/Foundation.h>
// Indicies to which we will set vertex array attibutes
enum
{
	POS_ATTRIB_IDX,
	NORMAL_ATTRIB_IDX,
	TEXCOORD_ATTRIB_IDX
};

@protocol Logging;
@interface BWGLVertexArray : NSObject
{
    CGLContextObj cgl_ctx;
    /// The GL
    GLuint vertexArray;
    unsigned _numElements;
    GLenum elementType;
    GLubyte* _elements;
    GLuint posBufferName;
}
- (id)  init: (CGLContextObj) cgl_ctx
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
