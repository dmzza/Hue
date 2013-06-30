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

@property (strong, nonatomic) NSDictionary *lights;
@property (strong, nonatomic) NSDictionary *groups;
@property (strong, nonatomic) PHLightState *lightState;
@property (strong, nonatomic) NSTimer *lightStateLoop;
@property (strong, nonatomic) UIColor *chosenColor;
@property (strong, nonatomic) UISlider *bpmSlider;
@property int fingers;
@property float bpm;
@property bool shouldSendLightState;
@property bool lightsOn;



@end
