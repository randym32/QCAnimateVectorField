/*
    Animate Vector Field Plugin
    Copyright (c) 2013-2014, Randall Maas

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

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>
#if __BIG_ENDIAN__
#define HostFormat QCPlugInPixelFormatARGB8
#else
#define HostFormat QCPlugInPixelFormatBGRA8
#endif

#import "BWAnimateVectorFieldPlugin.h"
#import "BWGrid+build.h"
#import "BWGrid+GLRender.h"
#import "BWGrid-Animate.h"

#define	kQCPlugIn_Name				@"Animated Vector Field"
#define	kQCPlugIn_Description		@"Produces an animated image of a given size containing am animation of a vector field.\nRandall Maas 2014"

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

@implementation BWAnimateVectorFieldPlugin

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic inputVectorColor,  outputImage, inputNumParticles, inputStructure, inputHeight, inputWidth;

NSDictionary* attributesForPort = nil;

+ (void) initialize
{
    // Create the dictionary for the attributes
    attributesForPort =
    @{
          // Port
          @"inputWidth" :
              @{
                  // Key                           Value
                  QCPortAttributeNameKey        : @"Image Width",
                  QCPortAttributeMaximumValueKey: [NSNumber numberWithUnsignedInteger:2048],
                  QCPortAttributeDefaultValueKey: [NSNumber numberWithUnsignedInteger:1440]
                },
          @"inputHeight":
              @{
                  QCPortAttributeNameKey        : @"Image Height",
                  QCPortAttributeMaximumValueKey: [NSNumber numberWithUnsignedInteger:2048],
                  QCPortAttributeDefaultValueKey: [NSNumber numberWithUnsignedInteger:1440]
                },
          @"inputNumParticles":
              @{
                  QCPortAttributeNameKey        : @"Number of Particles",
                  QCPortAttributeMaximumValueKey: [NSNumber numberWithUnsignedInteger:256000u],
                  QCPortAttributeDefaultValueKey: [NSNumber numberWithUnsignedInteger:32768]
              },
          @"inputVectorColor":
              @{
                  QCPortAttributeNameKey        : @"Color of vectors",
                  QCPortAttributeDefaultValueKey: [NSColor colorWithCalibratedRed: 0.0
                                                                            green: 1.0
                                                                             blue: 0.5
                                                                            alpha: 1.0]
                },
          @"inputStructure":
              @{
                  QCPortAttributeNameKey        : @"data",
                  QCPortAttributeDefaultValueKey: @""
                },
          /*
           @"inputStructure":
           @{
           QCPortAttributeNameKey        : @"Structure",
           },*/
          
          @"outputImage":
              @{
                  QCPortAttributeNameKey        : @"Animated vector image",
                }
    };
}


+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
    return @{
             QCPlugInAttributeNameKey       : kQCPlugIn_Name,
             QCPlugInAttributeCopyrightKey  : @"Randall Maas (c) 2014",
             QCPlugInAttributeDescriptionKey: kQCPlugIn_Description
            };
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
    return attributesForPort[key];
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a processor */
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) */
	//return kQCPlugInTimeModeIdle;//
    return kQCPlugInTimeModeTimeBase;
}

@end

@implementation BWAnimateVectorFieldPlugin (Execution)


- (id) init
{
    /* When plug-in is initialized. Initialized our array that will keep track or active plug-in controllers */
    if (!(self = [super init]))
    {
        return self;
    }
    
    return self;
}

/** This is used to load the given data
    @param data   The data
    @param width  The target width of the data grid
    @param height The target height of the data grid
 */
- (void) loadData: (NSDictionary*) data
            width: (int) width
           height: (int) height
{
    // releasing old field
    field = nil;
    if (!data)
    {
        return false;
    }
    // Allocate the field
    field = [[BWGrid alloc]
             initWithNumParticles: self.inputNumParticles
                            width: width
                           height: height];
    // loading data file
    if (![field interpretData: data 
                // scale for wind velocity (completely arbitrary--this value looks nice)
                velocityScale: width / (3996.0f)
     ])
    {
        field = nil;
    }
    
}

// This is the good version of the procedure
- (BOOL) execute: (id<QCPlugInContext>)context
          atTime: (NSTimeInterval)time
   withArguments: (NSDictionary*)arguments
{
    if ([self didValueForInputKeyChange:@"inputStructure"] || !time)
    {
        field = nil;
    }
    if (!field)
    {
        // Load the data
        [self loadData: self.inputStructure
                 width: self.inputWidth
                height:self.inputHeight];
    }

    // Detect when the number of particles has changed
    if ([self didValueForInputKeyChange:@"settingNumParticles"] || !time)
    {
        // Update the number of particles
        [field setNumParticles:self.inputNumParticles];
    }
    
    if ([self didValueForInputKeyChange:@"inputVectorColor"] || !time)
    {
        // updating color
        [field createTexture: self.inputVectorColor];
    }

    if (!field)
    {
        /* otherwise, don't produce any result image */
        self.outputImage = nil;
        return YES;
    }

    CGLContextObj					cgl_ctx = [context CGLContextObj];
    
    // Create the rendering target.   This later steps will render to a frame buffer
    // The framebuffer can contain textures
    GLuint frameBuffer = 0;
	/* Create temporary FBO to render in texture */
	glGenFramebuffersEXT(1, &frameBuffer);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffer);
    

    // Uppdate the anination
    [field animationStep];
    // Render the contents
    GLuint texName = [field draw: cgl_ctx];
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

    /* Check for OpenGL errors */
    GLenum status = glGetError();
    if(status)
    {
        NSLog(LogPrefix @"OpenGL error %04X", status);
        //When you're done using the texture, delete it. This will set texname to 0 and
        //delete all of the graphics card memory associated with the texture. If you
        //don't call this method, the texture will stay in graphics card memory until you
        //close the application.
        glDeleteTextures(1, &texName);
        texName = 0;
    }


    /* Make sure to flush as we use FBOs and the passed OpenGL context may not have a surface attached */
    glFlushRenderAPPLE();
    
    // Pass the results to Quartz Composer, by passing it the texture identifer
    id provider = nil;
    if (texName && texName)
    {
        provider= [context outputImageProviderFromTextureWithPixelFormat: HostFormat
                                                              pixelsWide: field.numXBins
                                                              pixelsHigh: field.numYBins
                                                                    name: texName
                                                                 flipped: YES
                                                         releaseCallback: _TextureReleaseCallback
                                                          releaseContext: NULL
                                                              colorSpace: [context colorSpace]
                                                        shouldColorMatch: YES];
    }
    glDeleteFramebuffersEXT(1, &frameBuffer);
    // Check for an error, and clean up if there was a problem
    if (!provider)
    {
        glDeleteTextures(1, &texName);
    }

	// Let Quartz know our output
	self.outputImage = provider;
	
	return YES;
}

@end


