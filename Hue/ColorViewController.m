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
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.view.backgroundColor = [UIColor blueColor];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint coord = [touch locationInView:nil];
    CGFloat hue = coord.y / 480;
    CGFloat saturation = (coord.x / 320);
    CGFloat brightness = 1.0;
    CGFloat alpha = 1.0;
    UIColor *chosenColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    self.view.backgroundColor = chosenColor;
    NSLog(@"h: %f s: %f b: %f", hue, saturation, brightness);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
