/*
    BWGrid.m
    Animate vector field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/22/13.
 
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

#import "BWGrid.h"
#import "BWGrid-Animate.h"
#import "BWGrid+GLRender.h"
#import "BWGLParameter.h"

unsigned long upper_power_of_two(unsigned long v)
{
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    return v+1;
    
}


@implementation BWGrid

/** Initialize the simuluation with a gien number of particles
    @param numParticles  The number of particles in the simulations
    @param width         The number of bins wide
    @param height        The number of bins high
    @param cgl_ctx       The core graphics GL context
    @param logger An object to log with
 */
- (id) initWithNumParticles: (int) numParticles
                      width: (int) width
                     height: (int) height
                    context: (CGLContextObj) _cgl_ctx
                     logger: (id<Logging>) logger
{
    cgl_ctx = _cgl_ctx;
    CGLShareGroupObj sharegroup = CGLGetShareGroup(cgl_ctx);
    gcl_gl_set_sharegroup(sharegroup);
    
    // First, try to obtain a dispatch queue that can send work to the
    // GPU in our system.
    if (OPENCL_GPU_EN)
    {
        _queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_GPU, NULL);
    }

    // In the event that our system does NOT have an OpenCL-compatible GPU,
    // we can use the OpenCL CPU compute device instead.
    if (_queue == NULL)
    {
        _queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_CPU, NULL);
    }
    
    if (!_queue)
    {
        // There was an error, so we can't work
        return nil;
    }

#if 0
    // Print the openCL device name and vendor
    char name_buf[128];
    char vendor_buf[128];
    cl_device_id device = gcl_get_device_id_with_dispatch_queue(_queue);
    clGetDeviceInfo(device, CL_DEVICE_NAME, sizeof(char)*128, name_buf, NULL);
    clGetDeviceInfo(device, CL_DEVICE_VENDOR, sizeof(char)*128, vendor_buf, NULL);
    NSLog (LogPrefix @"OpenCL name:%@  vendor:%@"
          , [[[NSString alloc] initWithUTF8String: name_buf] autorelease]
          , [[[NSString alloc] initWithUTF8String: vendor_buf] autorelease]
          );
#endif

#if POWER_OF_2_SIZE_EN
    // TEXTURE_2D requires that it must be a power of two:
    width = upper_power_of_two(width);
    height = upper_power_of_two(height);
#endif

    // Save the size
    self.numXBins = width;
    self.numYBins = height;
#if EXTRA_LOGGING_EN
    [logger logMessage:LogPrefix @"%d x %d w/ %d particles", width, height, numParticles];
#endif

    // Allocate the seed
    seed =gcl_malloc(sizeof(*seed), NULL, CL_MEM_READ_WRITE);

    // Load the shader program
    [self loadShaders: logger];
    
    // Tell the program the size of the output
    [shaderRenderSize setSize: NSMakeSize(width, height)
                       logger: logger];

    // Allocate the particles in the system
    [self setNumParticles: numParticles
                   logger: logger];
    
    // Tradition
    return self;
}


- (void)dealloc
{
    BW_free(hostVertices);
    BW_gcl_free(seed);
    BW_gcl_free(self.vectorField);
    BW_gcl_free(vertices);
#if !defined(OS_OBJECT_USE_OBJC_RETAIN_RELEASE) || !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
    // Finally, release your queue just as you would any GCD queue.
    if (_queue)
    {
        dispatch_release(_queue);
    }
#endif
}



@end
