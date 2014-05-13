/*
    BWGrid.h
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


#import <Foundation/Foundation.h>
#import <OpenCL/opencl.h>

#define FormatCL CL_BGRA

#ifndef LogPrefix
#define LogPrefix @"BWAnimateVectorFieldPlugin: "
#endif

@interface BWGrid: NSObject
{
    /// The Grand Central Dispatch queue
    dispatch_queue_t _queue;

    /// The particle positions
    cl_float2* vertices;
    cl_float2* hostVertices;
    /// The mapping of vertices to the texture
    float* textureMap;
    float* colorMap;
    
    /// The number if particles to simulate
    int _numParticles;
    
    /// The number of particles allocated
    int _numAllocatedParticles;
    
    /// The next particle to initialize
    int nextParticleInit;

    /// The seed for the random steps
    cl_ulong* seed;

    /// This is the buffer to hold the frame
    void* background;
    
    // backup colors
    float _colors[4];
    
    // Buffer to hold the texture
    uint8_t texture[4*32*32];
}

/// The number of bins in the x axis
@property int numXBins;

/// The number of bins in the y axis
@property int numYBins;

/// The vectors in space, organized as bins in a rectilinear grid
/// Each vector is represented as unit direction, and magnitude.
@property cl_float2* vectorField;

/// The max magnitude
@property float maxMagnitude;

/** Initialize the simuluation with a gien number of particles
    @param numParticles  The number of particles in the simulations
    @param width         The number of bins wide
    @param height        The number of bins high
*/
- (id) initWithNumParticles: (int)    numParticles
                      width: (int) width
                     height: (int) height
                           ;

@end

NS_INLINE void BW_free(void* x)
{
    if (x) free(x);
}

NS_INLINE void BW_gcl_free(void* x)
{
    if (x) gcl_free(x);
}


