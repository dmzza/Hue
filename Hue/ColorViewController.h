//
//  ColorViewController.h
//  Hue
//
//  Created by David Mazza on 6/29/13.
//  Copyright (c) 2013 David Mazza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HueSDK/SDK.h>
#import "PHConfigurationViewController.h"

@interface ColorViewController : UIViewController <PHConfigurationViewControllerDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UILabel *currentBridgeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lastLocalHeartbeatLabel;
@property (nonatomic, strong) NSDictionary *lights;
@property (nonatomic, strong) NSDictionary *groups;
@property (strong, nonatomic) PHLightState *lightState;
@property (strong, nonatomic) NSTimer *lightStateLoop;

- (IBAction)showLights:(id)sender;
- (IBAction)showBridgeConfig:(id)sender;

@property int fingers;
@property bool shouldSendLightState;
@property bool lightsOn;
@property (strong, nonatomic) UIColor *chosenColor;

@end
