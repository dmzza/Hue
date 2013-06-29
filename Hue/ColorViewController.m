//
//  ColorViewController.m
//  Hue
//
//  Created by David Mazza on 6/29/13.
//  Copyright (c) 2013 David Mazza. All rights reserved.
//

#import "ColorViewController.h"

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.fingers = MAX(0, MIN(2, self.fingers+touches.count));
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.fingers = MAX(0, MIN(2, self.fingers-touches.count));
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
    NSLog(@"fingers: %d h: %f s: %f b: %f", self.fingers, hue, saturation, brightness);   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
