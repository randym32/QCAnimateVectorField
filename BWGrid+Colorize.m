/*
    BWGrid+Colorize.m
    Animate Vector Field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/23/13.

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


#import "BWGrid+Colorize.h"
#import "BWGrid-Animate.h"
#include "gridColorize.cl.h"

@implementation BWGrid (Colorize)
/** Colorize the field of vector magnitudes
    @param srcBitmap  The background bitmap to draw onto
 */
- (void) colorize: (const void*) srcBitmap
{
    if (!self.vectorField)
        return;

    // Free the background
    BW_free(background);
    background = NULL;
    if (srcBitmap)
    {
        // Create a buffer for the background image
        background = valloc(4*self.numXBins*self.numYBins);
        
        // Copy the inage from given source bitmap
        memcpy(background, srcBitmap, 4*self.numXBins*self.numYBins);
        // I no longer color the rest of the background
        return;
    }
    else
    {
        // I no longer color the rest of the background
        return;
        // No source bitmap, just zero it
        memset(background, 0, 4*self.numXBins*self.numYBins);
    }
    
    // Dispatch the kernel block using one of the dispatch_ commands and the
    // queue created earlier.                                            // 5
    dispatch_sync(_queue, ^{
        // The N-Dimensional Range over which we'd like to execute our
        // kernel.  In this case, we're operating on a 2D buffer, so
        // it makes sense that the range is 2D.
        cl_ndrange range = {                                              // 6
            1,                     // The number of dimensions to use.
            
            {0, 0, 0},             // The offset in each dimension.  To specify
            // that all the data is processed, this is 0
            // in the test case.                   // 7
            
            {self.numXBins * self.numYBins, 0, 0},    // The global range—this is how many items
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
        
        
        // Allocate a buffer to hold the image
        cl_uchar4* image = gcl_malloc(sizeof(cl_uchar4)*self.numXBins*self.numYBins, background, CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR);
        
        // Perform the colorization
        self.maxMagnitude = 19.0*1440.0/self.numXBins;
        gridColorize_kernel(&range, self.vectorField,
                            self.maxMagnitude, image);
        
        BW_gcl_free(image);
    });
}


@end
