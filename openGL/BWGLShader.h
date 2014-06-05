//
//  GLShader.h
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
//
//

#import <Foundation/Foundation.h>
#include "glUtil.h"
@class BWGLVertexArray;
@class BWGLParameter;
@class BWFnNode;
@protocol Logging;


/// Maps the vert

@interface BWGLShader : NSObject
{
    CGLContextObj cgl_ctx;
}
/// The openGL handle for the vertex and fragment shader as a program
@property(readonly) GLuint prgName;

///
@property BWGLVertexArray* vertices;


- (id) initWithVertexShader: (NSObject*) vertexShaderSrc
             fragmentShader: (NSObject*) fragmentShaderSrc
                 withNormal: (BOOL) hasNormal
               withTexcoord: (BOOL) hasTexcoord
                    context:  (CGLContextObj) cgl_ctx
                     logger: (id<Logging>) logger
;
- (void) validate;
@end
@interface BWGLShader (Fn)

/** Looks up the shaders variable by name
    @param name  The name of the variable
    @returns nil on error, otherwise a reference to the shader parameter
 */
- (BWGLParameter*) variableReference: (NSString*) name;

/** Adds a node that is dependent on any changes to this one.
    @param node The node that depends on the shader setting
  */
- (void) addDestination: (BWFnNode*) node;

/** Something this node depends on has changed.. let all the nodes that depend on it know
 */
- (void) dependenciesChanged;

@end
@interface BWGLShader(Render)
/// This is used to set the vertex culling
- (void) setCulling:(GLenum) mode;

/// This is used to evaluate the shader 
- (void) evaluate: (id<Logging>) logger;

@end


