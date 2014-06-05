//
//  BWGLImage+QC.m
//  BW QC Utilities
//
//  Created by Randall Maas on 5/27/14.
//
//

#import "BWGLImage.h"


@implementation BWGLImage (QC)

static void _BufferReleaseCallback(const void* address, void* context)
{
    /* Destroy the CGContext and its backing */
    CFBridgingRelease(context);
}
static void _BufferReleaseCallback2(CGLContextObj cgl_ctx, GLuint name, void* context)
{
    /* Destroy the CGContext and its backing */
    CFBridgingRelease(context);
}


- (id) toQuartzComposer:(id<QCPlugInContext>) context
{
#if __BIG_ENDIAN__
#define format QCPlugInPixelFormatARGB8
#else
#define format QCPlugInPixelFormatBGRA8
#endif


    // Have it create the texture if not already
    [self texName: GL_TEXTURE_RECTANGLE_EXT
          context: [context CGLContextObj]
           logger: (id<Logging>) context];
    

    // Try to use the texture if it is present
    id provider = nil;
    if (_texName)
    {
        // Supposedly it wants it in GL_TEXTURE_RECTANGLE_EXT
        provider = [context outputImageProviderFromTextureWithPixelFormat: format
                                                               pixelsWide: self.width
                                                               pixelsHigh: self.height
                                                                     name: _texName
                                                                  flipped: YES
                                                          releaseCallback: _BufferReleaseCallback2
                                                           releaseContext: (void*) CFBridgingRetain(self)
                                                               colorSpace: [context colorSpace]
                                                         shouldColorMatch:YES];
    }
    if (!provider)
    {
        // I'm not sure if I should delete or not.
        /* Create image provider from backing */
        provider = [context outputImageProviderFromBufferWithPixelFormat: format
                                                              pixelsWide: self.width
                                                              pixelsHigh: self.height
                                                             baseAddress: bitmapData
                                                             bytesPerRow: rowByteSize
                                                         releaseCallback:_BufferReleaseCallback
                                                          releaseContext: (void*) CFBridgingRetain(self)
                                                              colorSpace: [context colorSpace]
                                                        shouldColorMatch: YES];
    }
    return provider;
}

@end


