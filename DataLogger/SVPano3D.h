#ifndef _3D
#define _3D

#include <math.h>
#define PI (3.141592653589793)
#define DEG2RAD(__ANGLE__) ((__ANGLE__) / 180.0 * PI)
#define RAD2DEG(__ANGLE__) ((__ANGLE__) / PI * 180.0)

class Vec2  {
public:
	Vec2(float vx, float vy) : x(vx) , y(vy) {}
	Vec2(const Vec2 &v) : x(v.x), y(v.y)  {}
	Vec2(){x=0;y=0;}
	
	//Square of the Vector magnitude
	inline float sqrNorm() {return x*x+y*y;}
	//Vector magnitude
	inline float norm() {return sqrt(sqrNorm());}
	inline void normalize() {float nrm=norm(); x=x/nrm; y=y/nrm;}
	//Returns dot product between this and b
	inline float dot(const Vec2 &b) { return x*b.x+y*b.y; }
	
	//Overloads the + and += operator per element intuitiVely i.e. behaviour is as one would expect
	inline Vec2 operator+ (const Vec2 &b){return Vec2(x+b.x,y+b.y);}
	inline Vec2 operator+ (const float &b){return Vec2(x+b,y+b);}
		
	//Overloads the - and -= operator per element intuitiVely i.e. behaviour is as one would expect
	inline Vec2 operator- (const Vec2 &b){return Vec2(x-b.x,y-b.y);}
	inline Vec2 operator- (const float &b){return Vec2(x-b,y-b);}
	
	inline Vec2 operator* (const float &b){return Vec2(x*b,y*b);}
	inline Vec2 operator/ (const Vec2 &b){return Vec2(x/b.x,y/b.y);}
	
	//Overloads the == operator per element intuitiVely i.e. identity iff all elements equal
	inline bool operator==(const Vec2 &b) {return (x==b.x && y==b.y);}
	
	float x,y;
	
};

class Vec3  {
public:
	Vec3(float vx, float vy, float vz) : x(vx) , y(vy), z(vz) {}
	Vec3(const Vec3 &v) : x(v.x) , y(v.y), z(v.z) {}
	Vec3(){x=0;y=0;z=0;}
	
	//Square of the Vector magnitude
	inline float sqrNorm() {return x*x+y*y+z*z;}
	//Vector magnitude
	inline float norm() {return sqrtf(sqrNorm());}
	inline void normalize() {float nrm=norm(); x=x/nrm; y=y/nrm; z=z/nrm;}
	//Returns dot product between this and b
	inline float dot(const Vec3 &b) { return x*b.x+y*b.y+z*b.z; }
	//Returns the corss product between this and b
	inline Vec3 cross(const Vec3 &b) {return Vec3(y*b.z-z*b.y,z*b.x-x*b.z,x*b.y-y*b.x);}
	
	//OVerloads the + and += operator per element intuitiVely i.e. behaviour is as one would expect
	inline Vec3 operator+ (const Vec3 &b){return Vec3(x+b.x,y+b.y,z+b.z);}
	inline Vec3 operator+ (const float &b){return Vec3(x+b,y+b,z+b);}
	
	//OVerloads the - and -= operator per element intuitiVely i.e. behaviour is as one would expect
	inline Vec3 operator- (const Vec3 &b){return Vec3(x-b.x,y-b.y,z-b.z);}
	inline Vec3 operator- (const float &b){return Vec3(x-b,y-b,z-b);}
	
	inline Vec3 operator* (const float &b){return Vec3(x*b,y*b,z*b);}
	inline Vec3 operator/ (const Vec3 &b){return Vec3(x/b.x,y/b.y,z/b.z);}
	
	//OVerlaods the == operator per element intuitiVely i.e. identity iff all elements equal
	inline bool operator==(const Vec3 &b) {return (x==b.x && y==b.y && z==b.z);}
	
	float x,y,z;
	
};

const Vec3 X=Vec3(1,0,0);
const Vec3 Y=Vec3(0,1,0);
const Vec3 Z=Vec3(0,0,1);
const Vec3 O=Vec3(0,0,0);

class TextureGrid  {
public:
	TextureGrid(int w,int h): width(w), height(h) {
		mesh=new Vec2[(w+1)*(h+1)];
		makeFlatPatch();
	}
	
	inline Vec2& get(int x, int y) {return mesh[x+y*(width+1)];}
	inline void set(int x, int y,const Vec2 &v) {mesh[x+y*(width+1)]=v;}
	
	void makeFlatPatch();
		
	~TextureGrid() {if (mesh!=NULL) delete [] mesh;}
	
	Vec2 *mesh;
	int width, height;
	
};

//this is a mesh where the components are Vec3s and is used for building structures
//every structure needs to call its texturizing function
//This Surface is basically just a grid and enables easy conceptual mapping from one thing to the next
//It will also quite easily enable physical simulations in the future
//
//USAGE: 
//surf=new Surface(100,100);
//surf->makeFlatPatch(100.0f, 50.0f);

class Surface {
public:
	Surface(int w, int h): width(w), height(h)  {
		numberOfVertices = (w+1) * (h+1);
		mesh=new Vec3 [numberOfVertices];
		textureCoords = new TextureGrid(w,h);
		faceIndices=NULL;
		normals=NULL;
		generateTriangleStripIndices();
	}

	inline Vec3& get(int x, int y) {return mesh[x+y*(width+1)];}
	inline void set(int x, int y,const Vec3 &v) {mesh[x+y*(width+1)]=v;}
	
	void makeSphere(float radius=1.0f);
	void makeCyclinder(const float &radius, const float &height);
	void makeFOVTexturePatch(float fovx=360.0f, float fovy=360.0f, float *rotationMatrix=NULL, char L_R_B=3);
	void makeFlatPatch(const float xOffset, const float yOffset, const float &width,const float &height,float depth);
	
	void rotate(const Vec3 &rotationVector,const float *angle);
	void translate(const Vec3 &translationVector, float distance);
	
	void generateTriangleIndices();
	void generateTriangleStripIndices();
	
	inline void* surfVertexData () { return (void*)mesh;}
	inline void* surfIndexData () { return (void*)faceIndices;}
	inline void* surfTextureData () { return (void*)textureCoords->mesh;} 
	inline unsigned short surfIndexDataSize() {return numberOfFaceIndices;}
	inline unsigned short surfVertexDataSize () {return numberOfVertices;}
	
	
	~Surface() { 
		if (mesh!=NULL) delete [] mesh; 
		if (textureCoords!=NULL) delete textureCoords;
		if (faceIndices!=NULL) delete [] faceIndices;
		if (normals!=NULL) delete [] normals;
	}
	
	Vec3 *mesh;	
	Vec3 *normals;
	TextureGrid *textureCoords;
	unsigned short *faceIndices;
	unsigned short numberOfFaceIndices;
	unsigned short numberOfVertices;
	int width, height;
};

//Helper functions
inline Vec3 sphericalToEuclidean(Vec2 theta_phi) //theta is theta_phi.x and phi is theta_phi.y
{
	return Vec3(sinf(theta_phi.x)*sinf(theta_phi.y),cosf(theta_phi.x)*sinf(theta_phi.y),cosf(theta_phi.y));
}


enum L_R_B {
	LEFT_WRAP,
	RIGHT_WRAP,
	BOTH
};

//This starts from the top i.e. +ve z and moves to -ve z (phi)
//It also rotates clockwise so any texture should be pasted as is. (theta)

inline Vec2 euclideanToSpherical(Vec3 xyz,char L_R_B=BOTH) //left, right, both
{
	return Vec2(atan2f(xyz.x, xyz.y)+((xyz.x<0 && L_R_B==BOTH)?(2*PI):0)+(L_R_B==LEFT_WRAP)*2*PI ,acosf(xyz.z/xyz.norm()));
}


#endif

