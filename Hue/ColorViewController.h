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

@property (nonatomic, strong) NSDictionary *lights;
@property (nonatomic, strong) NSDictionary *groups;
@property (strong, nonatomic) PHLightState *lightState;
@property (strong, nonatomic) NSTimer *lightStateLoop;

@property int fingers;
@property bool shouldSendLightState;
@property bool lightsOn;
@property (strong, nonatomic) UIColor *chosenColor;

@end
