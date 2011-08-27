
#if	__IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

#import <CoreMotion/CoreMotion.h>
#import "SVPanoXMotion.h"

//This is the low pass filter sample length that is used to maintain the moving average
#define LPF_RUN_LENGTH 20 

static XMotion *sharedXMotionManager = nil;

static bool GYRO = false;
static bool DMTN = false;
static bool COMP = false;
static bool ACCL = false;
static bool LOC  = false;

static int gyroRetain = 0;
static int dmtnRetain = 0;
static int compRetain = 0;
static int acclRetain = 0;
static int locRetain = 0;

static CMMotionManager *motionManager;
static CMAttitude *referenceAttitude;
static CLLocationManager *locationManager;
NSTimer *gyroCorrectionTimer;

static float latitude;
static float longitude;

static Vec3 gravity;
static Vec3 acceleration;
static Vec3 userAcceleration;
static Vec3 compass;
static Vec3 gyroscope;
static float rotation[9];

static int accelerationFilterPos;
static int userAccelerationFilterPos;
static int headingFilterPos;
static int gravityFilterPos;
static Vec3 LPFHeading [LPF_RUN_LENGTH];
static Vec3 LPFAcceleration [LPF_RUN_LENGTH];
static Vec3 LPFUserAcceleration [LPF_RUN_LENGTH];
static Vec3 LPFGravity [LPF_RUN_LENGTH];

static NSTimer *dataCollectionTimer;


@implementation XMotion


#pragma mark -
#pragma mark  Initialization

+ (XMotion*)sharedManager:(id) motionDelegate
{
    if (sharedXMotionManager == nil) {
        sharedXMotionManager = [[super allocWithZone:NULL] init];
		
		locationManager = [[CLLocationManager alloc] init];
		locationManager.headingFilter = kCLHeadingFilterNone;
		locationManager.delegate = motionDelegate;
		
		motionManager = [[CMMotionManager alloc] init];
		
		referenceAttitude = nil;
		
		dataCollectionTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 100.0)) 
															   target:sharedXMotionManager 
															 selector:@selector(collectMotionData) 
															 userInfo:nil repeats:TRUE];
		
    }
    return sharedXMotionManager;
}

#pragma mark -
#pragma mark  Callback data collection

- (void) collectMotionData
{
	if (DMTN) { //Here we get uacc, grav, rot
		CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
		CMAttitude *attitude = deviceMotion.attitude;
		CMAcceleration grav = deviceMotion.gravity;
		CMAcceleration userAcc = deviceMotion.userAcceleration;
		
		Vec3 tmp1=Vec3(grav.x,grav.y,grav.z);
		Vec3 tmp2=Vec3(userAcc.x,userAcc.y,userAcc.z);
		
		LPFGravity[gravityFilterPos++]=tmp1;
		LPFUserAcceleration[userAccelerationFilterPos++]=tmp2;
		
		if (userAccelerationFilterPos>=LPF_RUN_LENGTH) userAccelerationFilterPos=0;
		if (gravityFilterPos>=LPF_RUN_LENGTH) gravityFilterPos=0;
		
		gravity=Vec3();
		userAcceleration=Vec3();
		
		for (int i=0; i<LPF_RUN_LENGTH; i++) {
			gravity=gravity+LPFGravity[i]*(1.0/LPF_RUN_LENGTH);
			userAcceleration=userAcceleration+LPFUserAcceleration[i]*(1.0/LPF_RUN_LENGTH);
		}
		gravity.normalize();
		
		if (referenceAttitude != nil) [attitude multiplyByInverseOfAttitude:referenceAttitude];
		CMRotationMatrix rot=attitude.rotationMatrix;
		rotation[0]=rot.m11;rotation[1]=rot.m21;rotation[2]=rot.m31;
		rotation[3]=rot.m12;rotation[4]=rot.m22;rotation[5]=rot.m32;
		rotation[6]=rot.m13;rotation[7]=rot.m23;rotation[8]=rot.m33;
		
	} else	{
		if (ACCL) { //here we get only accelerometer data and it is stored in gravity. if we want something more complex then will need to update this section
			CMAccelerometerData *accel = motionManager.accelerometerData;
			
			Vec3 tmp=Vec3(accel.acceleration.x,accel.acceleration.y,accel.acceleration.z);
			acceleration = tmp; //this will be very noisy. if we want to use it we need to filter it and will need to update this section
			
			tmp.normalize();
			LPFAcceleration[accelerationFilterPos++]=tmp;
			if (accelerationFilterPos>=LPF_RUN_LENGTH) accelerationFilterPos=0;
			
			gravity=Vec3();
			
			for (int i=0; i<LPF_RUN_LENGTH; i++) {
				gravity=gravity+LPFAcceleration[i]*(1.0/LPF_RUN_LENGTH);
			}
			gravity.normalize();
		}
		
		if (GYRO) { //here we get only gyro data
			CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
			CMAttitude *attitude = deviceMotion.attitude;
			if (referenceAttitude != nil) [attitude multiplyByInverseOfAttitude:referenceAttitude];
			CMRotationMatrix rot=attitude.rotationMatrix;
			rotation[0]=rot.m11;rotation[1]=rot.m21;rotation[2]=rot.m31;
			rotation[3]=rot.m12;rotation[4]=rot.m22;rotation[5]=rot.m32;
			rotation[6]=rot.m13;rotation[7]=rot.m23;rotation[8]=rot.m33;
		} 
	}
	
	//and compass is dealt with by the callback
}

//This method provides us with heading data whenever the heading changes 
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading
{
	Vec3 tmp=Vec3(heading.x,heading.y,heading.z);
	tmp.normalize();
	LPFHeading[headingFilterPos++]=tmp;
	if (headingFilterPos>=LPF_RUN_LENGTH) headingFilterPos=0;
	
	compass=Vec3();
	
	for (int i=0; i<LPF_RUN_LENGTH; i++) {
		compass=compass+LPFHeading[i]*(1.0/LPF_RUN_LENGTH);
	}
	compass.normalize();
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	latitude=newLocation.coordinate.latitude;
	longitude=newLocation.coordinate.longitude;
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
	return YES;
}


#pragma mark -
#pragma mark  Gyro Correction
/*

+ (void) correctGyro
{
	CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
	CMAttitude *attitude = deviceMotion.attitude;

	//referenceAttitude = [deviceMotion.attitude retain];
	//[referenceAttitude release];

	//referenceAttitude = [[CMAttitude 
	
	//[attitude release];
	
	//[motionManager startGyroUpdates];
}

+ (void) setGyroCorrectionTimer
{
	gyroCorrectionTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(2.0 ) target:self selector:@selector(correctGyro) userInfo:nil repeats:TRUE];
}

+ (void) resetGyroCorrectionTimer
{
	[gyroCorrectionTimer invalidate];
	gyroCorrectionTimer=nil;
}*/

#pragma mark -
#pragma mark  Enables

+ (BOOL) enableGyroscope {
	if (!motionManager.gyroAvailable) {
		NSLog(@"Gyro not available");
		return NO;
	}
	
	gyroRetain++;
	if (GYRO) return YES;
	
	//These are for gyro correction
	if (![XMotion enableAccelerometer]) return NO;
	if (![XMotion enableCompass]) return NO;
	
	//[XMotion correctGyro];
	//[XMotion setGyroCorrectionTimer];
	
	CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
	CMAttitude *attitude = deviceMotion.attitude;
	referenceAttitude = [attitude retain];
	GYRO=true;
	[motionManager startGyroUpdates];
	return YES;
}

+ (BOOL) enableLocation {
	locRetain++;
	
	if (LOC) return YES;
	[locationManager startUpdatingLocation];
	LOC=true;
	return YES;
}

+ (BOOL) enableCompass {
	compRetain++;
	
	if (COMP) return YES;
	[locationManager startUpdatingHeading];
	COMP=true;
	return YES;
}

+ (BOOL) enableAccelerometer {
	if (!motionManager.accelerometerAvailable) {
		NSLog(@"Accelerometer not available");
		return NO;
	}
	
	acclRetain++;
	if (ACCL) return YES;		
	ACCL=true;
	[motionManager startAccelerometerUpdates];
	return YES;
	
}

+ (BOOL) enableDeviceMotion {
	if (!motionManager.deviceMotionAvailable) {
		NSLog(@"Device Motion not available");
		return NO;
	}
	
	dmtnRetain++;
	if (DMTN) return YES;
	CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
	DMTN=true;
	
	//[XMotion correctGyro];
	//[XMotion setGyroCorrectionTimer];
	
	
	CMAttitude *attitude = deviceMotion.attitude;
	referenceAttitude = [attitude retain];
	
	
	[motionManager startDeviceMotionUpdates];
	return YES;
	
}


#pragma mark -
#pragma mark  Disables

+ (void) disableGyroscope {
	
	gyroRetain--;
	[XMotion disableCompass];
	[XMotion disableAccelerometer];
	
	if (gyroRetain<=0) { 
		if (gyroRetain<0) NSLog(@"Tried to disable a non enabled sensor (gyro).");
		GYRO=false;
		gyroRetain=0;
		//[XMotion resetGyroCorrectionTimer];
		[motionManager stopGyroUpdates];
	}
}

+ (void) disableDeviceMotion {	
	dmtnRetain--;
	if (dmtnRetain<=0) { 
		if (dmtnRetain<0) NSLog(@"Tried to disable a non enabled sensor (dmtn).");
		DMTN=false;
		dmtnRetain=0;
		[motionManager stopDeviceMotionUpdates];
	}
}

+ (void) disableLocation{
	locRetain--;
	if (locRetain<=0) { 
		if (locRetain<0) NSLog(@"Tried to disable a non enabled sensor (dmtn).");
		LOC=false;
		locRetain=0;
		[locationManager stopUpdatingLocation];
	}
}

+ (void) disableCompass {
	compRetain--;
	if (compRetain<=0) { 
		if (compRetain<0) NSLog(@"Tried to disable a non enabled sensor (dmtn).");
		COMP=false;
		compRetain=0;
		[locationManager stopUpdatingHeading];
	}
}

+ (void) disableAccelerometer {
	acclRetain--;
	if (acclRetain<=0) {
		if (acclRetain<0) NSLog(@"Tried to disable a non enabled sensor (accl).");
		ACCL=false;
		acclRetain=0;
		[motionManager stopAccelerometerUpdates];
	}
}


#pragma mark -
#pragma mark  Gets

+ (Vec3)getGravity{
	if (ACCL) return gravity;
	NSLog(@"Acceleration not enabled. Cannot compute gravity.");
	return Vec3(0,0,0);
}

//SHOULD NOT USE THIS. NEEDS FILTERING
+ (Vec3)getAcceleration {
	if (ACCL) return acceleration;
	NSLog(@"Acceleration not enabled");
	return Vec3(0,0,0);
}

+ (float*)getGyroscope {
	if (GYRO) return rotation;
	NSLog(@"Gyroscope not enabled");
	return 0;
}

+ (float) getLatitude 
{
	if (LOC) return latitude;
	NSLog(@"Location no enabled");
	return -1;
}

+ (float) getLongitude 
{
	if (LOC) return longitude;
	NSLog(@"Location no enabled");
	return -1;
}

+ (Vec3)getCompass {
	if (COMP) return compass;
	NSLog(@"Compass not enabled");
	return Vec3(0,0,0);
}

+ (Vec3)getUserAcceleration {
	if (DMTN) return userAcceleration;
	NSLog(@"Device Motion must be enabled to get user acceleration.");
	return Vec3(0,0,0);
}

//This will return the best available device rotation
//info which we assume to be the gyro for the time being
+ (float*) getDeviceRotation {
	if (DMTN) return rotation;
	if (ACCL && COMP) { //this is NOT thread safe. there is no lock here. must update
		gravity.normalize();
		compass.normalize();
		Vec3 compassEast=gravity.cross(compass);
		compassEast.normalize();	
		Vec3 compassNorth=compassEast.cross(gravity);
		compassNorth.normalize();
		
		rotation[0]=compassEast.x;	rotation[1]=compassEast.y;	rotation[2]=compassEast.z;
		rotation[3]=compassNorth.x;	rotation[4]=compassNorth.y;	rotation[5]=compassNorth.z;		
		rotation[6]=-gravity.x;		rotation[7]=-gravity.y;		rotation[8]=-gravity.z;	
		NSLog(@"Get device rotation");
		return rotation;
	}
	NSLog(@"Not enough sensors enabled for attitude determination");
	return 0;
}


#pragma mark -
#pragma mark  Singleton stuff

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release
{
	//do nothing
}

- (id)autorelease
{
	return self;
}



@end

#endif