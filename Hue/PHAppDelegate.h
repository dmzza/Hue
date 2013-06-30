//
//  AppDelegate.h
//  Hue
//
//  Created by David Mazza on 6/29/13.
//  Copyright (c) 2013 David Mazza. All rights reserved.
//

#define UIAppDelegate  ((PHAppDelegate *)[[UIApplication sharedApplication] delegate])

#import <UIKit/UIKit.h>
#import "ColorViewController.h"
#import "PHBridgeSelectionViewController.h"
#import "PHBridgePushLinkViewController.h"
#import "PHSoftwareUpdateManager.h"

@class ViewController;
@class PHHueSDK;

@interface PHAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, PHBridgeSelectionViewControllerDelegate, PHBridgePushLinkViewControllerDelegate, PHSoftwareUpdateManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (nonatomic, strong) PHHueSDK *phHueSDK;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

#pragma mark - HueSDK

/**
 Starts the local heartbeat
 */
- (void)enableLocalHeartbeat;

/**
 Stops the local heartbeat
 */
- (void)disableLocalHeartbeat;

/**
 Starts a search for a bridge
 */
- (void)searchForBridgeLocal;

@end
