//
//  DataLoggerViewController.m
//  DataLogger
//
//  Created by GIPMac1 on 8/16/11.
//  Copyright 2011 Technion. All rights reserved.
//

#import "DataLoggerViewController.h"


@implementation DataLoggerViewController
@synthesize stopStart;


- (NSString *)dataFilePath:(NSString*) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *docDirectory = [paths objectAtIndex:0];
    return [docDirectory stringByAppendingPathComponent:fileName];
}

- (void) dataWrite:(NSString *) str {
    if (fh) {
        [fh writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        [fh writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (IBAction) start:(id)sender {
    NSLog(@"Opened file");
    [[NSFileManager defaultManager] createFileAtPath:[self dataFilePath:@"Data.txt"] contents:nil attributes:nil];
    fh = [[NSFileHandle fileHandleForWritingAtPath:[self dataFilePath:@"Data.txt"]]retain];
    
    [fh seekToEndOfFile];    
    
    if (motionManager.gyroAvailable) {
        motionManager.gyroUpdateInterval = 1.0/100;
        [motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
								   withHandler: ^(CMGyroData *gyroData, NSError *error)
		 {
             
             CMRotationRate rotate = gyroData.rotationRate;
             NSString *str=[NSString stringWithFormat:@"Gyro [%f, %f, %f] %f", rotate.x, rotate.y, rotate.z, gyroData.timestamp];
             [self dataWrite:str];       
		 }];
    }
    
    if (motionManager.deviceMotionAvailable) {
        motionManager.deviceMotionUpdateInterval = 1.0/100;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler: ^(CMDeviceMotion *motionData, NSError *error)
		 {
             
             CMRotationRate rotate = motionData.rotationRate;             
             CMAcceleration grav = motionData.gravity;
             CMAcceleration userAcc= motionData.userAcceleration;
             CMQuaternion attitude = motionData.attitude.quaternion;
             
             NSString *str=[NSString stringWithFormat:
                            @"DeviceMotion [%f,%f,%f] [%f,%f,%f] [%f,%f,%f] [%f,%f,%f,%f] %f", 
                            rotate.x, rotate.y, rotate.z, 
                            grav.x,grav.y,grav.z,
                            userAcc.x,userAcc.y,userAcc.z,
                            attitude.w,attitude.x,attitude.y,attitude.z,
                            motionData.timestamp];
             
             
             [self dataWrite:str];   
             
		 }];
    }
    
    [locationManager startUpdatingHeading];
    [locationManager startUpdatingLocation];
    
    self.stopStart.text=@"Running";
}


//This method provides us with heading data whenever the heading changes 
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading
{
    
    NSString *str=[NSString stringWithFormat:
                   @"Heading [%f,%f,%f]", 
                   heading.x, heading.y, heading.z];
    
    [self dataWrite:str];

}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	CLLocationDegrees latitude=newLocation.coordinate.latitude;
	CLLocationDegrees longitude=newLocation.coordinate.longitude;
    
    NSString *str=[NSString stringWithFormat:
                   @"Location [%f,%f]", 
                   latitude,longitude];
    
    [self dataWrite:str];
    
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
	return YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self becomeFirstResponder];
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction) stop:(id) sender {
    NSLog(@"Closed file");
    [motionManager stopGyroUpdates];
    [motionManager stopDeviceMotionUpdates];
    [locationManager stopUpdatingHeading];
    [locationManager stopUpdatingLocation];
    
    [[NSOperationQueue currentQueue] cancelAllOperations];
    [fh closeFile];
    fh=nil;
    self.stopStart.text=@"Not Running";
}

- (IBAction)emailFile:(id)sender {
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:@"My Subject"];
    [controller setMessageBody:@"Hello there." isHTML:NO]; 
    NSData *myData = [NSData dataWithContentsOfFile:[self dataFilePath:@"Data.txt"] ];
    [controller addAttachmentData:myData mimeType:@"mime" fileName:@"Data.txt"];	
    
    if (controller) [self presentModalViewController:controller animated:YES];
    [controller release];
    
}

- (IBAction)deleteFile:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self dataFilePath:@"Data.txt"] error:NULL];
}

- (void)dealloc
{
    [stopStart release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    motionManager = [[CMMotionManager alloc] init]; 
    locationManager = [[CLLocationManager alloc] init];
    locationManager.headingFilter = kCLHeadingFilterNone;
    locationManager.delegate = self;
}


- (void)viewDidUnload
{
    [self setStopStart:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
