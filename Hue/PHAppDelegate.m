//
//  AppDelegate.m
//  Hue
//
//  Created by David Mazza on 6/29/13.
//  Copyright (c) 2013 David Mazza. All rights reserved.
//

#import "PHAppDelegate.h"

#import "PHLoadingViewController.h"

#import <HueSDK/SDK.h>

@interface PHAppDelegate ()

@property (nonatomic, strong) PHLoadingViewController *loadingView;

@property (nonatomic, strong) UIAlertView *noConnectionAlert;
@property (nonatomic, strong) UIAlertView *noBridgeFoundAlert;
@property (nonatomic, strong) UIAlertView *authenticationFailedAlert;

@property (nonatomic, strong) PHBridgePushLinkViewController *pushLinkViewController;
@property (nonatomic, strong) PHBridgeSelectionViewController *bridgeSelectionViewController;

@property (nonatomic, strong) PHSoftwareUpdateManager *updateManager;

@end

@implementation PHAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    // Create sdk instance
    self.phHueSDK = [[PHHueSDK alloc] init];
    [self.phHueSDK startUpSDK];
    
    self.window.backgroundColor = [UIColor whiteColor];
    ColorViewController *colorVC = [[ColorViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:colorVC];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    // Listen for notifications
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    /***************************************************
     The SDK will send the following notifications in response to events
     *****************************************************/
    
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    /***************************************************
     If there is no authentication against the bridge this notification is sent
     *****************************************************/
    
    [notificationManager registerObject:self withSelector:@selector(notAuthenticated) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
    /***************************************************
     The local heartbeat is a regular  timer event in the SDK. Once enabled the SDK regular collects the current state of resources managed
     by the bridge into the Bridge Resources Cache
     *****************************************************/
    
    //[self enableLocalHeartbeat];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Stop heartbeat
    [self disableLocalHeartbeat];
    
    // Remove any open popups
    if (self.noConnectionAlert != nil) {
        [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:NO];
        self.noConnectionAlert = nil;
    }
    if (self.noBridgeFoundAlert != nil) {
        [self.noBridgeFoundAlert dismissWithClickedButtonIndex:[self.noBridgeFoundAlert cancelButtonIndex] animated:NO];
        self.noBridgeFoundAlert = nil;
    }
    if (self.authenticationFailedAlert != nil) {
        [self.authenticationFailedAlert dismissWithClickedButtonIndex:[self.authenticationFailedAlert cancelButtonIndex] animated:NO];
        self.authenticationFailedAlert = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Start heartbeat
    //[self enableLocalHeartbeat];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Hue" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Hue.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Loading view

/**
 Shows an overlay over the whole screen with a black box with spinner and loading text in the middle
 @param text The text to display under the spinner
 */
- (void)showLoadingViewWithText:(NSString *)text {
    // First remove
    [self removeLoadingView];
    
    // Then add new
    self.loadingView = [[PHLoadingViewController alloc] initWithNibName:@"PHLoadingViewController" bundle:[NSBundle mainBundle]];
    self.loadingView.view.frame = self.navigationController.view.bounds;
    [self.navigationController.view addSubview:self.loadingView.view];
    self.loadingView.loadingLabel.text = text;
}

/**
 Removes the full screen loading overlay.
 */
- (void)removeLoadingView {
    if (self.loadingView != nil) {
        [self.loadingView.view removeFromSuperview];
        self.loadingView = nil;
    }
}

#pragma mark - HueSDK

/**
 Notification receiver for successful local connection
 */
- (void)localConnection {
    // Check current connection state
    [self checkConnectionState];
    
    // Check if an update is available
    [self performSelector:@selector(updateCheck) withObject:nil afterDelay:1];
}

/**
 Checks for software update status
 */
- (void)updateCheck {
    if (self.updateManager == nil) {
        // Create update manager
        self.updateManager = [[PHSoftwareUpdateManager alloc] initWithDelegate:self];
    }
    // Check status
    [self.updateManager checkUpdateStatus];
}

/**
 Notification receiver for failed local connection
 */
- (void)noLocalConnection {
    // Check current connection state
    [self checkConnectionState];
}

/**
 Notification receiver for failed local authentication
 */
- (void)notAuthenticated {
    /***************************************************
     We are not authenticated so we start the authentication process
     *****************************************************/
    
    // Move to main screen (as you can't control lights when not connected)
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    // Dismiss modal views when connection is lost
    if (self.navigationController.presentedViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }
    
    // Remove no connection alert
    if (self.noConnectionAlert != nil) {
        [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:YES];
        self.noConnectionAlert = nil;
    }
    
    // Start local authenticion process
    /***************************************************
     doAuthentication will start the push linking
     *****************************************************/
    
    [self performSelector:@selector(doAuthentication) withObject:nil afterDelay:0.5];
}

/**
 Checks if we are currently connected to the bridge locally and if not, it will show an error when the error is not already shown.
 */
- (void)checkConnectionState {
    if (!self.phHueSDK.localConnected) {
        // Dismiss modal views when connection is lost
        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
        }
        
        // No connection at all, show connection popup
        if (self.noConnectionAlert == nil) {
            [self.navigationController popToRootViewControllerAnimated:YES];
            
            // Showing popup, so remove this view
            [self removeLoadingView];
            [self showNoConnectionDialog];
        }
    }
    else {
        // One of the connections is made, remove popups and loading views
        if (self.noConnectionAlert != nil) {
            [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:YES];
            self.noConnectionAlert = nil;
        }
        
        [self removeLoadingView];
    }
}

/**
 Shows the first no connection alert with more connection options
 */
- (void)showNoConnectionDialog {
    self.noConnectionAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection lost", @"No connection alert title")
                                                        message:NSLocalizedString(@"Connection to bridge is lost", @"No connection alert message")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Reconnect", @"No connection alert reconnect button"), NSLocalizedString(@"More", @"No connection alert more button"), nil];
    self.noConnectionAlert.tag = 1;
    [self.noConnectionAlert show];
}

/**
 Shows the second no connection alert with more connection options
 */
- (void)showNoConnectionMoreOptionsDialog {
    self.noConnectionAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"More options", @"Second No connection alert title")
                                                        message:NSLocalizedString(@"Choose your connection option", @"Second No connection alert message")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Find new bridge", @"No connection find new bridge button"), nil];
    self.noConnectionAlert.tag = 2;
    [self.noConnectionAlert show];
}

#pragma mark - Heartbeat control

/**
 Starts the local heartbeat with a 10 second interval
 */
- (void)enableLocalHeartbeat {
    /***************************************************
     The heartbeat processing collects data from the bridge
     so now try to see if we have a bridge already connected
     *****************************************************/
    
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil) {
        // Some bridge is known
        [self.phHueSDK enableLocalConnectionUsingInterval:10];
    }
    else {
        /***************************************************
         No bridge connected so start the bridge search process
         *****************************************************/
        
        // No bridge known
        [self searchForBridgeLocal];
    }
}

/**
 Stops the local heartbeat
 */
- (void)disableLocalHeartbeat {
    [self.phHueSDK disableLocalConnection];
}

#pragma mark - Bridge searching and selection

/**
 Search for bridges using UPnP and portal discovery, shows results to user or gives error when none found.
 */
- (void)searchForBridgeLocal {
    // Stop heartbeats
    [self disableLocalHeartbeat];
    
    // Show search screen
    [self showLoadingViewWithText:NSLocalizedString(@"Searching...", @"Searching for bridges text")];
    /***************************************************
     A bridge search is started using UPnP to find local bridges
     *****************************************************/
    
    // Start search
    PHBridgeSearching *bridgeSearch = [[PHBridgeSearching alloc] initWithUpnpSearch:YES andPortalSearch:YES];
    [bridgeSearch startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
        // Done with search, remove loading view
        [self removeLoadingView];
        /***************************************************
         The search is complete, check whether we found a bridge
         *****************************************************/
        
        // Check for results
        if (bridgesFound.count > 0) {
            // Results were found, show options to user (from a user point of view, you should select automatically when there is only one bridge found)
            self.bridgeSelectionViewController = [[PHBridgeSelectionViewController alloc] initWithNibName:@"PHBridgeSelectionViewController" bundle:[NSBundle mainBundle] bridges:bridgesFound delegate:self];
            /***************************************************
             Use the list of bridges, present them to the user, so one can be selected.
             *****************************************************/
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.bridgeSelectionViewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        }
        else {
            /***************************************************
             No bridge was found was found. Tell the user and offer to retry..
             *****************************************************/
            
            
            // No bridges were found, show this to the user
            self.noBridgeFoundAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No bridges", @"No bridge found alert title")
                                                                 message:NSLocalizedString(@"Could not find bridge", @"No bridge found alert message")
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"Retry", @"No bridge found alert retry button"), nil];
            self.noBridgeFoundAlert.tag = 1;
            [self.noBridgeFoundAlert show];
        }
    }];
}

/**
 Delegate method for PHbridgeSelectionViewController which is invoked when a bridge is selected
 */
- (void)bridgeSelectedWithIpAddress:(NSString *)ipAddress andMacAddress:(NSString *)macAddress {
    /***************************************************
     Removing the selection view controller takes us to
     the 'normal' UI view
     *****************************************************/
    
    // Remove the selection view controller
    self.bridgeSelectionViewController = nil;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    // Show a connecting view while we try to connect to the bridge
    [self showLoadingViewWithText:NSLocalizedString(@"Connecting...", @"Connecting text")];
    
    // Set SDK to use bridge and our default username (which should be the same across all apps, so pushlinking is only required once)
    NSString *username = [PHUtilities whitelistIdentifier];
    /***************************************************
     Set the username, ipaddress and mac address,
     as the bridge properties that the SDK framework will use
     *****************************************************/
    [UIAppDelegate.phHueSDK setBridgeToUseWithIpAddress:ipAddress macAddress:macAddress andUsername:username];
    
    /***************************************************
     Setting the hearbeat running will cause the SDK
     to regularly update the cache with the status of the
     bridge resources
     *****************************************************/
    
    // Start local heartbeat again
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

#pragma mark - Bridge authentication

/**
 Start the local authentication process
 */
- (void)doAuthentication {
    // Disable heartbeats
    [self disableLocalHeartbeat];
    /***************************************************
     To be certain that we own this bridge we must manually
     push link it. Here we display the view to do this.
     *****************************************************/
    
    // Create an interface for the pushlinking
    self.pushLinkViewController = [[PHBridgePushLinkViewController alloc] initWithNibName:@"PHBridgePushLinkViewController" bundle:[NSBundle mainBundle] hueSDK:UIAppDelegate.phHueSDK delegate:self];
    
    [self.navigationController presentViewController:self.pushLinkViewController animated:YES completion:^{
        /***************************************************
         Start the push linking process.
         *****************************************************/
        // Start pushlinking when the interface is shown
        [self.pushLinkViewController startPushLinking];
    }];
}

/**
 Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was successfull
 */
- (void)pushlinkSuccess {
    // Remove pushlink view controller
    /***************************************************
     Push linking succeeded we are authenticated against
     the chosen bridge.
     *****************************************************/
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    self.pushLinkViewController = nil;
    
    // Start local heartbeat
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

/**
 Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was not successfull
 */
- (void)pushlinkFailed:(PHError *)error {
    // Remove pushlink view controller
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    self.pushLinkViewController = nil;
    
    // Check which error occured
    if (error.code == PUSHLINK_NO_CONNECTION) {
        // No local connection to bridge
        [self noLocalConnection];
        
        // Start local heartbeat (to see when connection comes back)
        [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
    }
    else {
        // Bridge button not pressed in time
        self.authenticationFailedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Authentication failed", @"Authentication failed alert title")
                                                                    message:NSLocalizedString(@"Make sure you press the button within 30 seconds", @"Authentication failed alert message")
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:NSLocalizedString(@"Retry", @"Authentication failed alert retry button"), NSLocalizedString(@"More", @"Authentication failed alert more button"), nil];
        [self.authenticationFailedAlert show];
    }
}

#pragma mark - Alertview delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.noConnectionAlert && alertView.tag == 1) {
        // This is a no connection alert with option to reconnect or more options
        self.noConnectionAlert = nil;
        
        if (buttonIndex == 0) {
            // Retry, just wait for the heartbeat to finish
            [self showLoadingViewWithText:NSLocalizedString(@"Connecting...", @"Connecting text")];
        }
        else if (buttonIndex == 1) {
            // More options
            [self showNoConnectionMoreOptionsDialog];
        }
    }
    else if (alertView == self.noConnectionAlert && alertView.tag == 2) {
        // This is a no connection alert with the find new bridge and setup away from home options
        self.noConnectionAlert = nil;
        
        if (buttonIndex == 0) {
            // Find new bridge
            [self searchForBridgeLocal];
        }
    }
    else if (alertView == self.noBridgeFoundAlert && alertView.tag == 1) {
        // This is the alert which is shown when no bridges are found locally
        self.noBridgeFoundAlert = nil;
        
        if (buttonIndex == 0) {
            // Retry
            [self searchForBridgeLocal];
        }
    }
    else if (alertView == self.authenticationFailedAlert) {
        // This is the alert which is shown when local pushlinking authentication has failed
        self.authenticationFailedAlert = nil;
        
        if (buttonIndex == 0) {
            // Retry
            [self doAuthentication];
        }
        else if (buttonIndex == 1) {
            // Find new
            [self showNoConnectionMoreOptionsDialog];
        }
    }
}

#pragma mark - Software update delegate

- (BOOL)shouldShowMessageForNoSoftwareUpdate {
    // We should not show messages when there is no update
    return NO;
}

- (BOOL)shouldShowMessageForDownloadingSoftwareUpdate {
    // We should not show messages when we are still downloading updates
    return NO;
}

- (BOOL)shouldIgnorePostponeDate {
    // Postpone date should be honored
    return NO;
}

- (void)softwareUpdateStarted {
    // Remove any views which might obstuct the updating view
    if (self.navigationController.presentedViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }
    
    // Show loading view while updating
    [self showLoadingViewWithText:NSLocalizedString(@"Updating...", @"Updating text")];
}

- (void)softwareUpdateFinishedSuccessfull:(BOOL)success {
    // Remove loading view
    [self removeLoadingView];
}

@end
