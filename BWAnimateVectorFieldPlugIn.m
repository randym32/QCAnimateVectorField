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
#import "BWGrid+Colorize.h"
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
@dynamic inputVectorColor,  outputImage, inputImage, inputNumParticles, inputJSONURL;

NSDictionary* attributesForPort = nil;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:
            kQCPlugIn_Name,        QCPlugInAttributeNameKey,
            kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
    if (!attributesForPort)
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
                        QCPortAttributeDefaultValueKey: [NSNumber numberWithUnsignedInteger:720]
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
                        QCPortAttributeDefaultValueKey: [(id)CGColorCreateGenericRGB(0.0, 1.0, 0.50, 1.0) autorelease]
                     },
                @"inputJSONURL":
                    @{
                        QCPortAttributeNameKey        : @"URL for JSON data",
                        QCPortAttributeDefaultValueKey: @""
                     },
                /*
                @"inputStructure":
                    @{
                        QCPortAttributeNameKey        : @"Structure",
                    },*/
                @"inputImage":
                    @{
                        QCPortAttributeNameKey        : @"Image"
                    },
                
                @"outputImage":
                    @{
                        QCPortAttributeNameKey        : @"Animated vector image",
                     }
          };
    }
	/* Return the attributes for the plug-in property ports */
    return attributesForPort[key];
	
	return nil;
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

- (void) dealloc
{
    [field  release];
    [super dealloc];
}


/** This is used to load the data file from the given URL
    @param url    The URL for data file
    @param width  The target width of the data grid
    @param height The target height of the data grid
 */
- (void) loadDataFile:(NSString*) url
                width: (int) width
               height: (int) height
{
    // releasing old field
    [field release];
    field = nil;
    if (!url)
    {
        return false;
    }
    // Allocate the field
    field = [[BWGrid alloc]
             initWithNumParticles: self.inputNumParticles
                            width: width
                           height: height];
    // loading data file
    if (![field loadJSON: url
                // scale for wind velocity (completely arbitrary--this value looks nice)
          velocityScale: width / (5192.0f)
     ])
    {
        [field release];
        field = nil;
    }
    
}


/** Load the background image from another quartz composer input
    @param qCImage
 */
- (void) loadBackground:(id<QCPlugInInputImageSource>) qcImage
{
	/* Figure out pixel format and colorspace to use */
	CGColorSpaceRef   colorSpace = [qcImage imageColorSpace];
    CGColorSpaceModel colorModel = CGColorSpaceGetModel(colorSpace);
	NSString*	     pixelFormat = QCPlugInPixelFormatBGRA8;
	if(colorModel == kCGColorSpaceModelMonochrome)
        pixelFormat = QCPlugInPixelFormatI8;
	else if(colorModel == kCGColorSpaceModelRGB)
        pixelFormat = HostFormat;
    else
    {
        // Uknown color model;
        // Use a blank background
    L1:
        backgroundIsNull = true;
        if (!field)
        {
            // Load the data for the file
            [self loadDataFile: self.inputJSONURL
                         width: 1440
                        height: 720];
            [field colorize:NULL];
            [field createTexture: self.inputVectorColor];
        }
        return;
    }

    /* Get a buffer representation from the image in its native colorspace */
	if(![qcImage lockBufferRepresentationWithPixelFormat: pixelFormat
                                              colorSpace: colorSpace
                                               forBounds: [qcImage imageBounds]])
    {
        // Can't lock the buffer
        goto L1;
    }

    // Check the input image size
    int width =[qcImage bufferPixelsWide];
    int height=[qcImage bufferPixelsHigh];
    if (!width || !height)
    {
    L2: /* Release buffer representation */
        [qcImage unlockBufferRepresentation];
        goto L1;
    }

    // Copy the source image
    uint bytesPerRow = [qcImage bufferBytesPerRow];
    if (4*width == bytesPerRow)
    {
        // Resize the model if it doesn't match
        if (  width  != field.numXBins
           || height != field.numYBins
            )
        {
            // Reload the data for the new size
            [self loadDataFile: self.inputJSONURL
                         width: width
                        height: height];
        }
        // And give it the new background image
        [field colorize:[qcImage bufferBaseAddress]];
        backgroundIsNull = false;
    }
    else
    {
        // We couldn't read the image conveniently.  This could be fixed in the future
        goto L2;
    }
    
    /* Release buffer representation */
	[qcImage unlockBufferRepresentation];
}


// This is the good version of the procedure
- (BOOL) execute: (id<QCPlugInContext>)context
          atTime: (NSTimeInterval)time
   withArguments: (NSDictionary*)arguments
{
    if (  [self didValueForInputKeyChange:@"inputJSONURL"]
       || [self didValueForInputKeyChange:@"inputImage"]
        )
    {
        [field release];
        field = nil;
    }

    // Detect when the image has changed
    if (  !field
        /* Make sure we have a new image */
        || backgroundIsNull)
    {
        // The background image changed, update
        [self loadBackground: self.inputImage];
    }
    if ([self didValueForInputKeyChange:@"inputNumParticles"])
    {
        // Update the number of particles
        [field setNumParticles:self.inputNumParticles];
    }
    
    if ([self didValueForInputKeyChange:@"inputVectorColor"])
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
    glDeleteFramebuffersEXT(1, &frameBuffer);

    glFlush();
    /* Check for OpenGL errors */
    GLenum status = glGetError();
    if(status)
    {
        NSLog(@"OpenGL error %04X", status);
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
    id provider = [context outputImageProviderFromTextureWithPixelFormat: HostFormat
                                                              pixelsWide: field.numXBins
                                                              pixelsHigh: field.numYBins
                                                                    name: texName
                                                                 flipped: YES
                                                         releaseCallback: _TextureReleaseCallback
                                                          releaseContext: NULL
                                                              colorSpace: [context colorSpace]
                                                        shouldColorMatch: YES];
    // Check for an error, and clean up if there was a problem
    if (!provider)
    {
        glDeleteTextures(1, &texName);
        return NO;
    }

	// Let Quartz know our output
	self.outputImage = provider;
	
	return YES;
}

@end


