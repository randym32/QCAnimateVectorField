//
//  GLShadedMesh.m
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
//
//

#import "BWGLShader.h"
#import "BWGLVertexArray.h"
//#import "BWFnEdge.h"
#import "glUtil.h"
#import "glErrorLogging.h"

@implementation BWGLShader(render)

- (void) setCulling:(GLenum) mode
{
    if (mode)
    {
        // Cull back faces now that we no longer render
        // with an inverted matrix
        glCullFace(mode);
    }
}


- (void) evaluate: (id<Logging>) logger
{
    // Set up to use the shader.  We do this before as f may set some variables
    glUseProgram(self.prgName);
	LogGLErrors();
   
    [self.vertices draw];
    // Check for errors to make sure all of our setup went ok
    LogGLErrors();
}
@end
