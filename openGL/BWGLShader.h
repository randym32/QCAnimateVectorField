//
//  GLShader.h
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
#include "glUtil.h"
@class BWGLVertexArray;
@class BWGLParameter;
@class BWFnNode;
@protocol Logging;


/** This maps pixels on in the destination to colors, usually from an input set of triangles and textures
 */
@interface BWGLShader : NSObject
{
    /// The core graphics GL context
    CGLContextObj cgl_ctx;
}
/// The openGL handle for the vertex and fragment shader as a program
@property(readonly) GLuint prgName;

///
@property BWGLVertexArray* vertices;


/** Initializes the shader program
    @param cgl_ctx   The core graphics GL context
    @returns nil on error, otherwise a reference to the object
*/
- (id) initWithVertexShader: (NSObject*) vertexShaderSrc
             fragmentShader: (NSObject*) fragmentShaderSrc
                 withNormal: (BOOL) hasNormal
               withTexcoord: (BOOL) hasTexcoord
                    context:  (CGLContextObj) cgl_ctx
                     logger: (id<Logging>) logger
;

/** Checks that the program and its settings are reasonable.
 */
- (void) validate;
@end
@interface BWGLShader (param)

/** Looks up the shaders variable by name
    @param name  The name of the variable
    @returns nil on error, otherwise a reference to the shader parameter
 */
- (BWGLParameter*) variableReference: (NSString*) name;
@end
@interface BWGLShader (Fn)
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


