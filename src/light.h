#ifndef __LIGHT_H__
#define __LIGHT_H__
#include "vector.h"
#include "camera.h"
#include "Textures/texture.h"
#include "Textures/colortexture.h"

class Light{
  public:
   unsigned char* color;
   unsigned char* getColor(unsigned char a, unsigned char b, unsigned char c);
   Vector center;
   Light(const Vector & cente, unsigned char* colo);
   ~Light();
};

struct LightNode{
   Light* data;
   LightNode* prev, *next;
};

class Shape;
struct ShapeNode{
   Shape* data;
   ShapeNode* prev, *next;
   // every triangle is a seperate node in this list,
   // so every ray is getting checked against all 3168 triangles even if it wasnt anywhere near
   // the mesh. so we put a sphere around the whole mesh and save it on the first triangle's
   // node, and if a ray misses the sphere we can just skip the entire mesh.
   ShapeNode* meshLast; // last triangle of mesh 
   Vector boundCenter; //center of bounding sphere
   double boundRadius;  // radius of bounding sphere
};

// returns true if the ray gets close enough to the sphere that it might hit something in it
inline bool rayNearBound(ShapeNode* n, Vector point, Vector dir){
   Vector toCenter = n->boundCenter - point;     
   double t = toCenter.dot(dir) / dir.mag2();    // how far along the ray the closest point is
   Vector closest = point + dir*t;         
   Vector diff = n->boundCenter - closest;
   return sqrt(diff.mag2()) <= n->boundRadius;   // if its within the radius we have to check the triangles
}

class Autonoma{
public:
   Camera camera;
   Texture* skybox;
   unsigned int depth;
   ShapeNode *listStart, *listEnd;
   LightNode *lightStart, *lightEnd;
   Autonoma(const Camera &c);
   Autonoma(const Camera &c, Texture* tex);
   void addShape(Shape* s);
   void removeShape(ShapeNode* s);
   void addLight(Light* s);
   void removeLight(LightNode* s);
   ~Autonoma();
};

void getLight(double* toFill, Autonoma* aut, Vector point, Vector norm, unsigned char r);

#endif
