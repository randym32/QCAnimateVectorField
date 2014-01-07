/*
    Move the particles
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

    Inpsired by Cameron Beccario, https://github.com/cambecc/earth
*/

#define M_PI   3.1415926535897932384626433832795f


// --- Randomize particle location -----------------------
/**Returns a random number
   @param seed The Seed to the random number generator
   @param max  The max number to return
   @returns A random number
 */
float random(__global ulong* seed, uint max)
{
    *seed = (*seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1);
    uint result = (*seed) >> 16;
    return result % max;
}


/** Find a random location for a particle
    @param numXBins The number of bins in the x axis
    @param numYBins The number of bins in the y axis
    @param seed     The random number seed
    @returns A {float2} vector
*/
float2 particleRandomize(
                       int numXBins, int numYBins,
                       __global ulong* seed
                       )
{
    float n = (random(seed, numYBins*10-1)/(numYBins*10.0f))*M_PI;
    float c = cos(n);
    float y = c*90.0f+180.0f;
    if (y >= 180.0f) y -= 180.0f;
    y *= numYBins/180.0f;
    return (float2)( random(seed, numXBins*10-1)/10.0
                   , y
                   );
}


/** This randomizes a single particle
    @param positions   Set of vectors for each particle
    @param positions_t The set of new vectors for each particle
    @param numXBins The number of bins in the x axis
    @param numYBins The number of bins in the y axis
    @param dataGrid The grid of vectors (mapped to an array)
    @param seed     The random number seed
 */
__kernel void particleInit( __global float2*   vertex   // position of each particle
                          , int numXBins, int  numYBins    // The size of the data grid
                          , __global ulong*    seed        // A randomizer
                          )
{
    // The global id of the work item.  (the index i)
    int idx = get_global_id(0);
    // Particle isn't visible, but it still moves through the field.
    // particle has escaped the grid, never to return...
    float2 position = particleRandomize(numXBins, numYBins, seed);

    // Path from (x,y) to (xt,yt) is visible, so add this particle to the appropriate draw bucket.
    vertex[4*idx  ] = position;
    vertex[4*idx+1] = position;
    vertex[4*idx+2] = position;
    vertex[4*idx+3] = position;
}



/** This moves a single particle
    @param positions   Set of vectors for each particle
    @param positions_t The set of new vectors for each particle
    @param numXBins    The number of bins in the x axis
    @param numYBins    The number of bins in the y axis
    @param vectorField The field of vectors (mapped to an array), with normalized magnitude within the field
    @param seed     The random number seed
*/
__kernel void particleMove(  __global float2*   vertex    // position of each particle box
                           , float              dT          // Range from [0, 1]
                           , int numXBins, int  numYBins    // The size of the vector field
                           , __global float2*   vectorField // The data in the grid
                           , __global ulong*    seed        // A randomizer
                           )
{
    // The global id of the work item.  (the index i)
    int idx = get_global_id(0);
    
    // The positions are actually vertices (4)
    int idx4 = 4*idx;
    
    // The left two are the key ones
    // Get the particle position
    float2 position = vertex[idx4]+dT*(vertex[idx4+1]-vertex[idx4]);
    float2 position2 = (float2)(position.x+1.5f, position.y+1.5f);
    float m;
    float2 position_t, position_t2;
    if (position.y >= numYBins || position.x >= numXBins)
    {
        m = 1e12;
    }
    else
    {
        // vector at current position
        float2 v = vectorField[(int)position.x + ((int) position.y)*numXBins];
        m = v.x*v.x + v.y*v.y;

        position_t = position + v;
        position_t2= position2+ v;
        position_t2.x+=0.5f;
    }
    if (  position_t.x < 0.0)
    {
        // The particle is squished up against the meridian line.
        position.x = position_t.x = position_t2.x = position2.x = numXBins-0.6;
    }
    if (position_t.x>= numXBins)
    {
        // The particle is squished up against the meridian line.
        position.x = position_t.x = position_t2.x = position2.x = 0.0;
    }
    if (position_t.y < 0.0)
    {
        position_t.y = 0;
        position_t2.y = 0;
    }
    else if (position_t.y>= numYBins)
    {
        position_t.y = numYBins-1;
        position_t2.y = numYBins-1;
    }
    if ( m>1e11 || m <4.0
       )
    {
        // The particle is moving too fast or too slow; get rid of it
        position_t = particleRandomize(numXBins, numYBins, seed);
        position_t2= position_t;
        position = position_t;
        position2= position_t;
        m=0.0;
    }
    
    // Path from (x,y) to (xt,yt) is visible, so add this particle to the appropriate draw bucket.
    vertex[idx4]   = position;
    vertex[idx4+1] = position_t;
    vertex[idx4+2] = position_t2;
    vertex[idx4+3] = position2;
}


