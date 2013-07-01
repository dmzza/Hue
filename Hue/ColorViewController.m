//
//  ColorViewController.m
//  Hue
//
//  Created by David Mazza on 6/29/13.
//  Copyright (c) 2013 David Mazza. All rights reserved.
//

#import "ColorViewController.h"
#import "PHAppDelegate.h"

#import <HueSDK/SDK.h>

@interface ColorViewController ()

@end

@implementation ColorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.chosenColor = [UIColor colorWithHue:1.0 saturation:0.0 brightness:1.0 alpha:1.0];
        self.view.backgroundColor = self.chosenColor;
        self.view.multipleTouchEnabled = YES;
        self.fingers = 0;
        self.bpm = 60;
        self.shouldSendLightState = NO;
        self.lightsOn = YES;
        [self updateLights];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    // Listen for notifications
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(updateLights) forNotification:LIGHTS_CACHE_UPDATED_NOTIFICATION];
    
    self.bpmSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, 100, 300, 40)];
    self.bpmSlider.minimumValue = 2;
    self.bpmSlider.maximumValue = 120;
    [self.bpmSlider addTarget:self action:@selector(updateBPM) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.bpmSlider];
    
    self.lightStateLoop = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendLightState) userInfo:nil repeats:YES];
}

- (void)updateBPM {
    self.bpm = self.bpmSlider.value;
    float interval = 60/self.bpm;
    NSLog(@"bpm: %f ", self.bpmSlider.value);
    [self.lightStateLoop invalidate];
    self.lightStateLoop = nil;
    self.lightStateLoop = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(sendLightState) userInfo:nil repeats:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.fingers = MAX(0, MIN(2, self.fingers+touches.count));
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.fingers = MAX(0, MIN(2, self.fingers-touches.count));
    self.shouldSendLightState = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint coord = [touch locationInView:nil];
    CGPoint previousCoord = [touch previousLocationInView:nil];
    CGFloat deltaHue = (coord.y - previousCoord.y) / 480;
    CGFloat deltaSaturation = (coord.x - previousCoord.x) / 320;
    CGFloat deltaBrightness = (coord.x - previousCoord.x) / 320;
    CGFloat h, s, b, a;
    [self.chosenColor getHue:&h saturation:&s brightness:&b alpha:&a];
    CGFloat hue = h;
    CGFloat saturation = s;
    CGFloat brightness = b;
    CGFloat alpha = 1.0;
    switch (self.fingers) {
        case 1:
            hue = MAX(0.0, MIN(1.0, (h+deltaHue)));
            saturation = MAX(0.0, MIN(1.0, (s+deltaSaturation)));
            break;
        case 2:
            brightness = MAX(0.0, MIN(1.0, (b+deltaBrightness)));
            break;
    }
    self.chosenColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    self.view.backgroundColor = self.chosenColor;
    if (brightness < 0.5)
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    else
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    NSLog(@"groups: %d fingers: %d h: %f s: %f b: %f", self.groups.count, self.fingers, hue, saturation, brightness);
    
    // Create an empty lightstate
    self.lightState = [[PHLightState alloc] init];
    
    [self.lightState setOnBool:YES];
    
    [self.lightState setHue:[NSNumber numberWithInt:((int)(hue * 65535))]];
    
    [self.lightState setSaturation:[NSNumber numberWithInt:((int)(saturation * 255))]];
    
    //[self.lightState setBrightness:[NSNumber numberWithInt:((int)(brightness * 255))]];
    
    [self.lightState setTransitionTime:[NSNumber numberWithInt:20]];
    
//    self.shouldSendLightState = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sendLightState {
    
    /***************************************************
     The BridgeSendAPI is used to send commands to the bridge.
     Here we are updating the settings chosen by the user
     for the selected light.
     These settings are sent as a PHLightState to update
     the light with the given light identifiers.
     Subsequent checking of the Bridge Resources cache after the next heartbeat will
     show that changed settings have occurred.
     *****************************************************/
    id<PHBridgeSendAPI> bridgeSendAPI = [[[PHOverallFactory alloc] init] bridgeSendAPI];
    if (self.shouldSendLightState) {
        // Create a bridge send api, used for sending commands to bridge locally
        self.shouldSendLightState = NO;
        self.lightsOn = YES;
        [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:self.lightState completionHandler:^(NSArray *errors) {
            if (errors.count > 0) {
                self.shouldSendLightState = YES;
            }
        }];
    } else {
        int brightness, transition;
        if (!self.lightsOn) {
            brightness = 254;
            transition = 20;
            self.lightsOn = YES;
        } else {
            brightness = 50;
            transition = 20;
            self.lightsOn = NO;
        }
        PHLightState *lightState = [[PHLightState alloc] init];
    
        [lightState setBrightness:[NSNumber numberWithInt:brightness]];
        [lightState setTransitionTime:[NSNumber numberWithInt:(int)(600/(self.bpm/2))]];
        
        [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:lightState completionHandler:^(NSArray *errors) {
//            if (errors.count > 0) {
//                PHError *error = errors[0];
//                NSLog(error.description);
//            }
        }];
        
        CGFloat h, s, b, a;
        [self.chosenColor getHue:&h saturation:&s brightness:&b alpha:&a];
        UIColor *adjustedBrightness = [UIColor colorWithHue:h saturation:s brightness:(float)(brightness/255.0) alpha:a];
        self.view.backgroundColor = adjustedBrightness;
        
    }
    
    
    
//    NSEnumerator *enumerator = [self.lights keyEnumerator];
//    id key;
//    
//    while ((key = [enumerator nextObject])) {
//        /* code that uses the returned key */
//        PHLight *light = [self.lights objectForKey:key];
//        self.sendingLightState = YES;
//        // Send lightstate to light
//        [bridgeSendAPI updateLightStateForId:light.identifier withLighState:self.lightState completionHandler:^(NSArray *errors) {
//            self.sendingLightState = NO;
//            if (errors.count > 0) {
//                /* Maybe if an error occurs we should check the current lightstate for each light and reset the app to reflect the current colors 
//                 */
////                for(PHError *error in errors) {
////                    // Error occured
////                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
////                                                                 message:error.description
////                                                                delegate:nil
////                                                       cancelButtonTitle:nil
////                                                       otherButtonTitles:@"Ok", nil];
////                    [errorAlert show];
////                }
//            }
//        }];
//    }
}

/**
 Gets the list of lights from the cache
 */
- (void)updateLights {
    // Gets lights from cache
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    self.lights = cache.lights;
    self.groups = cache.groups;
}

#pragma mark - Configuration view controller delegate

- (void)closeConfigurationView:(PHConfigurationViewController *)configurationView {
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)startSearchForBridge:(PHConfigurationViewController *)configurationView {
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    [UIAppDelegate searchForBridgeLocal];
}

#pragma mark - Notification receivers

/**
 Notification receiver for successful local connection
 */
- (void)localConnection {
}

/**
 Notification receiver for failed local connection
 */
- (void)noLocalConnection {
}

@end
