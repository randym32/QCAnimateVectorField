/*
    BWGrid+build.m
    Animate vector field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/25/13.
 
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

#import "BWGrid+build.h"
#import "gridBuild.cl.h"
#import "BWGrid-Animate.h"

@implementation BWGrid (build)

/** This converts an NSArray of NSNumber to a c-array of floats
    @param ary The 
 */
- (cl_float*) arrayOfFloat: (NSDictionary*) ary
{
    // Get the number of items in the array
    NSUInteger count = [ary count];
    // Allocate space to hold it
    cl_float* ret = malloc(sizeof(cl_float)*count);
    // Copy them to a machine format
    for (NSObject* key in ary)
    {
        ret[[(NSNumber*)key intValue]] = [ary[key] floatValue];
    }
    // return
    return ret;
}


/** Load the flow data
    @param data          The flow data.
    @param velocityScale how much to scale the velocity magnitude by
    @return true on success, false on failure
*/
- (bool) interpretData: (NSDictionary*) data
         velocityScale: (float) velocityScale
{
    NSError *e = nil;
    if (!data || e)
    {
        NSLog(LogPrefix @"error, could not load: %@", e);
        return false;
    }
    [self start: data
  velocityScale: velocityScale];
    return true;
}


/** Load the data in the JSON file
    @param path  The path to the JSON file.
    @param velocityScale how much to scale the velocity magnitude by
 */
- (void) start: (NSDictionary*) jsonArray
 velocityScale: (float) velocityScale
{
    // There will be 2 objects in the JSON aray
    cl_float* uary = NULL;  // The host c-array of the u components
    cl_float* vary = NULL;  // The host c-array of the u components
    NSUInteger count;
    cl_float2 delta;    // distance between grid points (e.g., 2.5 deg lon, 2.5 deg lat)
    cl_uint2  srcSize;  // number of grid points W-E and N-S (e.g., 144 x 73) in the original data
    cl_float2 origin;   // the grid's origin (e.g., 0.0E, 90.0N)
    for (NSObject* key in jsonArray)
    {
        NSDictionary* vector = jsonArray[key];
        // There are two keys: header, data
        NSDictionary* header          = vector[@"header"];
        // Copy the header info.. this is often duplicationed, so don't wory about it
        delta.x = [header[@"dx"] floatValue];
        delta.y = [header[@"dy"] floatValue];
        origin.x= [header[@"lo1"] floatValue];
        origin.y= [header[@"la1"] floatValue];
        srcSize .x = [header[@"nx"] unsignedIntegerValue];
        srcSize .y = [header[@"ny"] unsignedIntegerValue];

        count = [vector[@"data"] count];

        // Get the vector of data
        long          parameterNumber = [(NSNumber*) header[@"parameterNumber"] longValue];
        if (2 == parameterNumber)
        {
            // The u component
            uary = [self arrayOfFloat:vector[@"data"]];
        } else if (3 == parameterNumber)
        {
            // The v component
            vary = [self arrayOfFloat:vector[@"data"]];
        }
    }
#if EXTRA_LOGGING_EN
    if (!vary)
    {
        NSLog(LogPrefix @"no v array");
    }
    if (!uary)
    {
        NSLog(LogPrefix @"no u array");
    }
    if (!count)
    {
        NSLog(LogPrefix @"The u / v array had zero count");
    }
    if (srcSize .x < 1)
    {
        NSLog(LogPrefix @"The x size is less than 1");
    }
    if (srcSize .y < 1)
    {
        NSLog(LogPrefix @"The y size is less than 1");
    }
#endif
    if (!vary || !uary)
        return;
    

#if EXTRA_LOGGING_EN
    NSLog(LogPrefix @"%s,%d: allocating grid", __FILE__, __LINE__);
#endif
    // Build the GCL local versions of the array
    cl_float* cl_uary = gcl_malloc(sizeof(*cl_uary)* count, uary, CL_MEM_READ_ONLY | CL_MEM_USE_HOST_PTR);
    cl_float* cl_vary = gcl_malloc(sizeof(*cl_vary)* count, vary, CL_MEM_READ_ONLY | CL_MEM_USE_HOST_PTR);

    // Allocate enough for the temporary data grid
    bool isContinuous = floor(srcSize.x * delta.x) >= 360;
    int srcStride = srcSize.x+(isContinuous? 1:0);
    
    // Continuous grids wrap around and have an extra column
    // BUG: see the 1+srcSize.y?  that means I'm going off the edge
    cl_float2* srcField = gcl_malloc(sizeof(*srcField)*srcStride*(1+srcSize.y), NULL, CL_MEM_READ_WRITE);

    // Creating the first stage grid
    // Dispatch the kernel block using one of the dispatch_ commands and the
    // queue created earlier.                                            // 5
#if EXTRA_LOGGING_EN
    NSLog(LogPrefix @"%s,%d: preparing grid", __FILE__, __LINE__);
#endif
    dispatch_sync(_queue, ^{
        // The N-Dimensional Range over which we'd like to execute our
        // kernel.  In this case, we're operating on a 1D buffer, so
        // it makes sense that the range is 1D.
        cl_ndrange range =
        {                                              // 6
            1,                     // The number of dimensions to use.
            
            {0, 0, 0},             // The offset in each dimension.  To specify
            // that all the data is processed, this is 0
            // in the test case.                   // 7
            
            {srcSize.y, 0, 0},    // The global range—this is how many items
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

        // Call to build the source grid
        gridBuild_kernel(&range
                   , cl_uary, cl_vary
                   // The number of source grid points W-E and N-S (e.g., 144 x 73)
                   , srcSize
                   , delta
                   , isContinuous
                   , srcField
                   );
    });
    

    // We need to update the origin now, as we have rotated the view
    origin.x += 90.0;
    // Update the number of columns that are actually in the grid at this time
    srcSize.x = srcStride;

    // Allocate the memory for the vector field
    cl_float2* myVectorField = gcl_malloc(sizeof(*myVectorField)*numXBins*numYBins, 0, CL_MEM_READ_WRITE);

    // Interpolate to the target field size
#if EXTRA_LOGGING_EN
    NSLog(LogPrefix @"%s,%d: interpolating", __FILE__, __LINE__);
#endif
    dispatch_sync(_queue, ^{
        // Call to build the interpolated / metric-distance grid
        cl_ndrange range2 = {                                              // 6
            2,                     // The number of dimensions to use.
            
            {0, 0, 0},             // The offset in each dimension.  To specify
            // that all the data is processed, this is 0
            // in the test case.                   // 7
            
            {numXBins, numYBins, 0},    // The global range—this is how many items
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

        cl_uint2 tgtSize = {numXBins, numYBins};
        gridInterpolate_kernel(&range2, srcSize, srcField,
                               origin, delta, velocityScale,
                               tgtSize, numXBins, myVectorField);
    });

    self.vectorField = myVectorField;
    
#if EXTRA_LOGGING_EN
    NSLog(LogPrefix @"%s,%d: freeing resources", __FILE__, __LINE__);
#endif
    // Release the resources
    BW_gcl_free(srcField);
    BW_gcl_free(cl_uary);
    BW_gcl_free(cl_vary);
    BW_free(uary);
    BW_free(vary);
    
    // Randomize the position of the particles
    [self randomizeParticles: _numParticles];
}
@end
