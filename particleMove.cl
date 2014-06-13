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
    float m =random(seed, (numXBins*numYBins));
    float yy=(int)(m/numXBins);
    float xx = m - numXBins*yy;
    
    float c = (cos(M_PI*yy/numYBins)+1.0)*0.5;
    c*=c;
    
    return (float2){xx,(numYBins-1)*(1.0-c)};
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
    // The positions are actually vertices (2)
    int idx2 = 2*idx;
    vertex[idx2  ] = position;  // tail
    vertex[idx2+1] = position;  // head
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
    int idx2 = 2*idx;
    
    // The left two are the key ones
    // Get the particle position
    float2 position = vertex[idx2];
    float2 _v = vectorField[(int)position.x + ((int) position.y)*numXBins];
    float2 v =_v*dT;
    float2 origPosition = position;
    position = position+v;

    float2 position_t;
    // This to handle wrap around on either edge as elegantly as possible
    if (position.x < 0.0 && v.x < 0.0)
    {
        // We wrapped around to the "east end of the world"
        position.x = numXBins-0.1;
        
        // Sanity check the y coordinate (otherwise we can misindex)
        if (position.y >= numYBins) position.y = numYBins-0.5;
        else if (position.y < 0.0) position.y=0.0;
        
        position_t = position + v;
    }
    else if (position.x > numXBins && v.x > 0.0)
    {
        // We wrapped around to the "west end of the world"
        position.x =0.0;
        position.y = 0.5*(position.y+origPosition.y);
        // Sanity check the y coordinate (otherwise we can misindex)
        if (position.y >= numYBins) position.y = numYBins-0.5;
        else if (position.y < 0.0) position.y=0.0;
        position_t = position + v;
    }

    // Did the particle go out of bounds?
    else if (position.y< 0.0 || position.y >= numYBins-1.0)
    {
        // The particle is moving too fast or too slow; get rid of it
        position_t = particleRandomize(numXBins, numYBins, seed);
        position = position_t;
    }
    else
    {
        // vector at current position
        float m = _v.x*_v.x + _v.y*_v.y;

        position_t = position + v;

        if (m < 2.0)
        {
            // The particle is moving too fast or too slow; get rid of it
            position_t = particleRandomize(numXBins, numYBins, seed);
            position = position_t;
        }
    }

    
    // Path from (x,y) to (xt,yt) is visible, so add this particle to the appropriate draw bucket.
    vertex[idx2]   = position;
    vertex[idx2+1] = position_t;
}


