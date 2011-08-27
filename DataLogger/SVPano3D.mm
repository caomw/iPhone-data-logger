#include "SVPano3D.h"
//-----------------------------------------------------------
//-----------------------------------------------------------

void TextureGrid::makeFlatPatch(){
	float dw=1.0f/(width);
	float dh=1.0f/(height);
	
	for (int j=0; j<=this->height; j++) {
		for (int i=0; i<=this->width; i++) {
			set(i, j, Vec2(i*dw,1-j*dh));
		}
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------


void Surface::makeCyclinder(const float &radius, const float &height){}

//This makes a spherical valued patch then converts to euclidean about axis (0,0,1) 
//and then rotates by the rotation matrix
//and then converts back to spherical coords 
//and then converts those coordinates to texture coords
void Surface::makeFOVTexturePatch(float fovx, float fovy,float *xform,char L_R_B){
	float startTheta=-tanf(DEG2RAD(fovx/2));
	float startPhi=-tanf(DEG2RAD(fovy/2));
	float dTheta=-2*startTheta/this->width;
	float dPhi=-2*startPhi/this->height;
	
	Vec3 pos3,tmp;
	Vec2 pos2;
	float w=1;
	for (int j=0; j<=this->height; j++) {
		for (int i=0; i<=this->width; i++) {
			pos3=Vec3(startTheta	+ dTheta*i,
					  startPhi		+ dPhi*j,
					  -1);
			
			pos3.normalize();
			
			//This matrix inverts the model view matrix used to define the gryos
			//3d world position and hence provides the correct position of the
			//texture on the map
			
			tmp.x=xform[0]*pos3.x+xform[1]*pos3.y+xform[2]*pos3.z+xform[3];
			tmp.y=xform[4]*pos3.x+xform[5]*pos3.y+xform[6]*pos3.z+xform[7];
			tmp.z=xform[8]*pos3.x+xform[9]*pos3.y+xform[10]*pos3.z+xform[11];
			w=   xform[12]*pos3.x+xform[13]*pos3.y+xform[14]*pos3.z+xform[15];

			tmp=tmp*(1.0/w);
			tmp.normalize();
			pos2=euclideanToSpherical(tmp,L_R_B);
			pos2=pos2/Vec2(2*PI,PI);
			
			pos3=Vec3(pos2.x,1-pos2.y,0);//this must be inverted because a texture coord system is upside down
			set(i, j, pos3);
		//	NSLog(@"x: %f y:%f",pos3.x,pos3.y);
		}
	}
	
	///NSLog(@"FlatPatch surface generated");
}

void Surface::makeFlatPatch(const float xOffset, const float yOffset, const float &width,const float &height,float depth){
	float dw=width/(this->width);
	float dh=height/(this->height);
	
	if (normals==NULL) normals=new Vec3[numberOfVertices];
	
	for (int j=0; j<=this->height; j++) {
		for (int i=0; i<=this->width; i++) {
			set(i, j, Vec3(xOffset+i*dw,yOffset+j*dh,depth));
			normals[i+(this->width+1)*j]=Z;
			Vec3 tmp=get(i, j);
		}
	}
}

void Surface::makeSphere(float radius){
	float dtheta = 2*PI/width;
	float dphi = PI/height;
	
	if (normals==NULL) normals=new Vec3[numberOfVertices];
	
	for (int j=0; j<=height; j++) {
		for (int i=0; i<=width; i++) {
			set(i, j, sphericalToEuclidean(Vec2(i*dtheta,j*dphi)));
			normals[i+(width+1)*j]=get(i,j);
		}
	}
}

void Surface::rotate(const Vec3 &rotationVector,const float *angle){}
void Surface::translate(const Vec3 &translationVector, float distance=0){}

void Surface::generateTriangleIndices() {}

void Surface::generateTriangleStripIndices() { 
	numberOfFaceIndices=height*((width+1)*2+2);
	if (faceIndices!=NULL)
		delete [] faceIndices;
	faceIndices=new unsigned short [numberOfFaceIndices];
	
	for (int j=0; j<height; j++) {
		for (int i=0; i<=width; i++) {
			faceIndices[i*2+((width+1)*2+2)*j]=i+(width+1)*j;
			faceIndices[i*2+1+((width+1)*2+2)*j]=i+(width+1)*(j+1);
		}
		faceIndices[(width+1)*2+((width+1)*2+2)*j]=width+(width+1)*(j+1);
		faceIndices[(width+1)*2+1+((width+1)*2+2)*j]=(width+1)*(j+1);
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
