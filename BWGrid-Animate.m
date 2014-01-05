/*
    BWGridAnimate.m
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

#import "BWGrid-Animate.h"
#include "particleMove.cl.h"

@implementation BWGrid (Animate)

/** This is used to change the number of particles in the animation
    @param numParticles  The number particles that should be in the system
 
    Note: if the number of particles is more than were allocated, the system may toss out the
    old points
 */
- (void) setNumParticles : (int) numParticles
{
    // Check for the easiest case first
    if (numParticles <= _numParticles)
    {
        // Just reduce the number of particles in the system
        _numParticles = numParticles;
        return;
    }

    // count the number of new particles
    int count = numParticles - _numParticles;
    // Set up the starting point of what to allocate
    nextParticleInit = _numParticles;

    // Check for the next easiest case
    if (numParticles <= _numAllocatedParticles)
    {
        // increment the number of particles we are tracking
        _numParticles = numParticles;
        // Randomize the new particles
        [self randomizeParticles: count];
        return;
    }
    
    // Okay we have to allocate them them
    if (vertices)
    {
        gcl_free(vertices);
    }

    // Allocate the array of particle positions
    if (!hostVertices)
    {
        hostVertices= calloc(sizeof(*hostVertices), 4*numParticles);
        _numAllocatedParticles= numParticles;
    }
    else
    {
        cl_float2* newHostVertices = realloc(hostVertices, sizeof(*hostVertices)* 4*numParticles);
        // Check that realloc worked
        if (newHostVertices)
        {
            _numAllocatedParticles= numParticles;
            hostVertices = newHostVertices;
        }
        else
            NSLog(@"realloc failed");
    }
    // The number of particles that
    _numParticles= _numAllocatedParticles;
    
    // Set up the openCL access to the particles
    vertices    = gcl_malloc(sizeof(*vertices)*_numAllocatedParticles*4, hostVertices, CL_MEM_READ_WRITE|CL_MEM_USE_HOST_PTR|CL_MEM_HOST_READ_ONLY);
    
    // Create the texture map vertices
    if (textureMap)
    {
        free(textureMap);
    }
    textureMap = valloc(sizeof(float)*_numAllocatedParticles*2*4);
    for (int I = 0; I < _numAllocatedParticles*4*2;)
    {
        textureMap[I++] = 1.0;
        textureMap[I++] = 1.0;
        textureMap[I++] = 0;
        textureMap[I++] = 1.0;
        textureMap[I++] = 0;
        textureMap[I++] = 1.0;
        textureMap[I++] = 1.0;
        textureMap[I++] = 0;
    }
    
    if (colorMap)
    {
        free(colorMap);
    }
    colorMap = valloc(sizeof(float*)*4*4*_numAllocatedParticles);
    // Randomize the new particles
    [self randomizeParticles: count];
}


/** This is used to randomize the num next particles
    @param numParticles The number of particles to initialize
 */
- (void) randomizeParticles: (int) numParticles
{
    int maxNumParticles = _numParticles - nextParticleInit;
    if (maxNumParticles < numParticles)
    {
        numParticles = maxNumParticles;
    }
    
    // Dispatch the kernel block using one of the dispatch_ commands and the
    // queue created earlier.                                            // 5
    if (numParticles > 0)
    dispatch_sync(_queue, ^{
        // The N-Dimensional Range over which we'd like to execute our
        // kernel.  In this case, we're operating on a 1D buffer, so
        // it makes sense that the range is 1D.
        cl_ndrange range = {                                              // 6
            1,                     // The number of dimensions to use.
            
            {nextParticleInit, 0, 0},             // The offset in each dimension.  To specify
            // that all the data is processed, this is 0
            // in the test case.                   // 7
            
            {numParticles, 0, 0},    // The global range—this is how many items
            // IN TOTAL in each dimension you want to
            // process.
            
            {0, 0, 0}            // The local size of each workgroup.  This
            // determines the number of work items per
            // workgroup.  It indirectly affects the
            // number of workgroups, since the global
            // size / local size yields the number of
            // workgroups.  In this test case, there are
            // NUM_VALUE / wgs workgroups.
        };

        nextParticleInit += numParticles;
        if (nextParticleInit >= _numParticles)
        {
            nextParticleInit = 0;
        }
        
        
        // Perform the particle movement
        particleInit_kernel(&range
                           , vertices
                           , self.numXBins, self.numYBins,
                            seed
                            );
        
    });
}


/// Update the animation
- (void) animationStep
{
    if (!self.vectorField)
        return;
    [self randomizeParticles: 100];
    // Dispatch the kernel block using one of the dispatch_ commands and the
    // queue created earlier.                                            // 5
    dispatch_sync(_queue, ^{
        // The N-Dimensional Range over which we'd like to execute our
        // kernel.  In this case, we're operating on a 1D buffer, so
        // it makes sense that the range is 1D.
        cl_ndrange range = {                                              // 6
            1,                     // The number of dimensions to use.
            
            {0, 0, 0},             // The offset in each dimension.  To specify
            // that all the data is processed, this is 0
            // in the test case.                   // 7
            
            {_numParticles, 0, 0},    // The global range—this is how many items
            // IN TOTAL in each dimension you want to
            // process.
            
            {0, 0, 0}            // The local size of each workgroup.  This
            // determines the number of work items per
            // workgroup.  It indirectly affects the
            // number of workgroups, since the global
            // size / local size yields the number of
            // workgroups.  In this test case, there are
            // NUM_VALUE / wgs workgroups.
        };

        // Perform the particle movement
        particleMove_kernel(&range
                            , vertices
                            , 0.0800f
                            , self.numXBins, self.numYBins
                            , self.vectorField
                            , seed
                            );
    });
}

@end
