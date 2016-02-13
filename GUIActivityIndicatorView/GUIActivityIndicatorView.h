//
//  GUIActivityIndicatorView.h
//  GUIActivityIndicatorView
//

#import <Cocoa/Cocoa.h>

@interface GUIActivityIndicatorView : NSView

@property (nonatomic) BOOL hidesWhenStopped;
@property (nonatomic, readonly, getter=isAnimating) BOOL animating;

- (void)startAnimating;
- (void)stopAnimating;

@end
