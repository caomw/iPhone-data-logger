//
//  DataLoggerViewController.h
//  DataLogger
//
//  Created by GIPMac1 on 8/16/11.
//  Copyright 2011 Technion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPanoXMotion.h"
#import "SVPano3D.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>

@interface DataLoggerViewController : UIViewController <CLLocationManagerDelegate,MFMailComposeViewControllerDelegate>{
    
    UIButton *actionButton;
    CMMotionManager *motionManager;	
    CLLocationManager *locationManager;
    NSFileHandle* fh;
    UILabel *stopStart;
}
@property (nonatomic, retain) IBOutlet UILabel *stopStart;

- (IBAction) start:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction)emailFile:(id)sender;
- (IBAction)deleteFile:(id)sender;

@end
