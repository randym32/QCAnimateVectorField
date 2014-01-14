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

@implementation BWGrid
/** Initialize the simuluation with a gien number of particles
    @param numParticles  The number of particles in the simulations
    @param width         The number of bins wide
    @param height        The number of bins high
 */
- (id) initWithNumParticles: (int)    numParticles
                      width: (int) width
                     height: (int) height
{
    // First, try to obtain a dispatch queue that can send work to the
    // GPU in our system.                                             // 2
    _queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_GPU, NULL);
    
    // In the event that our system does NOT have an OpenCL-compatible GPU,
    // we can use the OpenCL CPU compute device instead.
    if (_queue == NULL)
    {
        _queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_CPU, NULL);
    }

#if 0
    // Print the openCL device name and vendor
    char name_buf[128];
    char vendor_buf[128];
    cl_device_id device = gcl_get_device_id_with_dispatch_queue(_queue);
    clGetDeviceInfo(device, CL_DEVICE_NAME, sizeof(char)*128, name_buf, NULL);
    clGetDeviceInfo(device, CL_DEVICE_VENDOR, sizeof(char)*128, vendor_buf, NULL);
    NSLog (@"OpenCL name:%@  vendor:%@"
          , [[[NSString alloc] initWithUTF8String: name_buf] autorelease]
          , [[[NSString alloc] initWithUTF8String: vendor_buf] autorelease]
          );
#endif
    
    // Save the size
    self.numXBins = width;
    self.numYBins = height;

    // Allocate the seed
    seed =gcl_malloc(sizeof(*seed), NULL, CL_MEM_READ_WRITE);

    // Create a buffer for the background image
    background = valloc(4*self.numXBins*self.numYBins);
    
    // Allocate the particles in the system
    [self setNumParticles: numParticles];
    
    // Tradition
    return self;
}

- (void)dealloc
{
    BW_free(colorMap);
    BW_free(background);
    BW_free(textureMap);
    BW_gcl_free(seed);
    BW_gcl_free(self.vectorField);
    BW_gcl_free(vertices);
    BW_free(hostVertices);
    // Finally, release your queue just as you would any GCD queue.    // 11
    dispatch_release(_queue);

    [super dealloc];
}



@end
