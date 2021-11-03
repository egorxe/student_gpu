// c++ -o raster2d raster2d.cpp
// (c) www.scratchapixel.com
 
#include <cstdio> 
#include <cstdlib> 
#include <cstring> 
#include <fstream> 
 
typedef float Vec2[2]; 
typedef float Vec3[3]; 
typedef unsigned char Rgb[3]; 
 
inline 
float edgeFunction(const Vec2 &a, const Vec2 &b, const Vec2 &c) 
{ return (c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0]); } 
 
int main(int argc, char **argv) 
{ 
    //Vec2 v0 = {491.407, 411.407}; 
    Vec2 v0 = {500,500}; 
    Vec2 v1 = {148.593, 68.5928}; 
    Vec2 v2 = {148.593, 411.407}; 
    Vec3 c0 = {1, 0, 0}; 
    Vec3 c1 = {0, 1, 0}; 
    Vec3 c2 = {0, 0, 1}; 
 
    const uint32_t w = 512; 
    const uint32_t h = 512; 
 
    Rgb *framebuffer = new Rgb[w * h]; 
    memset(framebuffer, 0x0, w * h * 3); 
 
    float area = edgeFunction(v0, v1, v2); 
 
    for (uint32_t j = 0; j < h; ++j) { 
        for (uint32_t i = 0; i < w; ++i) { 
            Vec2 p = {i + 0.5f, j + 0.5f}; 
            float w0 = edgeFunction(v1, v2, p); 
            float w1 = edgeFunction(v2, v0, p); 
            float w2 = edgeFunction(v0, v1, p); 
            if (w0 >= 0 && w1 >= 0 && w2 >= 0) { 
                w0 /= area; 
                w1 /= area; 
                w2 /= area; 
                float r = w0 * c0[0] + w1 * c1[0] + w2 * c2[0]; 
                float g = w0 * c0[1] + w1 * c1[1] + w2 * c2[1]; 
                float b = w0 * c0[2] + w1 * c1[2] + w2 * c2[2]; 
                framebuffer[j * w + i][0] = (unsigned char)(r * 255); 
                framebuffer[j * w + i][1] = (unsigned char)(g * 255); 
                framebuffer[j * w + i][2] = (unsigned char)(b * 255); 
            } 
        } 
    } 
 
    std::ofstream ofs; 
    ofs.open("./raster2d.ppm"); 
    ofs << "P6\n" << w << " " << h << "\n255\n"; 
    ofs.write((char*)framebuffer, w * h * 3); 
    ofs.close(); 
 
    delete [] framebuffer; 
 
    return 0; 
} 
