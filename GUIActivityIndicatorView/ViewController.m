//
//  ViewController.m
//  GUIActivityIndicatorView
//

#import "ViewController.h"

// AppKit is insisting on enabling the button when modifying its value
@interface GUIDisabledButton : NSButton
@end

@implementation GUIDisabledButton

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:NO];
}

@end

@implementation ViewController

- (IBAction)unhideActivityIndicator:(id)sender
{
    self.activityIndicatorView.hidden = NO;
}

@end
