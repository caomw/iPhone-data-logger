

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "SVPano3D.h"

//This is a singleton class. Im sure the design is not that good but its a first attempt
//at using it so at least experience was gained

@interface XMotion : NSObject<UIAccelerometerDelegate,CLLocationManagerDelegate> {
}

+ (XMotion*)sharedManager:(id) motionDelegate;


+ (Vec3) getGravity;
+ (Vec3) getUserAcceleration;
+ (Vec3) getCompass;
+ (float) getLatitude;
+ (float) getLongitude;
+ (float*) getGyroscope;
+ (float*) getDeviceRotation;

+ (BOOL) enableGyroscope;
+ (BOOL) enableDeviceMotion;
+ (BOOL) enableLocation;
+ (BOOL) enableCompass;
+ (BOOL) enableAccelerometer;

+ (void) disableGyroscope;
+ (void) disableDeviceMotion;
+ (void) disableLocation;
+ (void) disableCompass;
+ (void) disableAccelerometer;

@end
