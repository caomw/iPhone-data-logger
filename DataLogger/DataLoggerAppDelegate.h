//
//  DataLoggerAppDelegate.h
//  DataLogger
//
//  Created by GIPMac1 on 8/16/11.
//  Copyright 2011 Technion. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataLoggerViewController;

@interface DataLoggerAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet DataLoggerViewController *viewController;

@end
