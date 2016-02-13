//
//  GUIActivityIndicatorView.m
//  GUIActivityIndicatorView
//

#import <QuartzCore/QuartzCore.h>
#import "GUIActivityIndicatorView.h"

#define COLOR_WITH_RGB_VALUES(R, G, B) [NSColor colorWithRed:(R)/255.0 green:(G)/255.0 blue:(B)/255.0 alpha:1.0].CGColor
#define DARK_BLUE()    COLOR_WITH_RGB_VALUES( 61, 128, 249)
#define LIGHT_BLUE()   COLOR_WITH_RGB_VALUES( 43,  93, 173)
#define DARK_RED()     COLOR_WITH_RGB_VALUES(231, 132, 124)
#define LIGHT_RED()    COLOR_WITH_RGB_VALUES(221,  74,  65)
#define DARK_YELLOW()  COLOR_WITH_RGB_VALUES(254, 210,  89)
#define LIGHT_YELLOW() COLOR_WITH_RGB_VALUES(254, 222, 130)
#define DARK_GREEN()   COLOR_WITH_RGB_VALUES( 29, 131,  76)
#define LIGHT_GREEN()  COLOR_WITH_RGB_VALUES( 40, 169, 100)

#define TRANSFORM_VALUE(transform) [NSValue valueWithCATransform3D:(transform)]
#define COLOR_VALUE(color)         (__bridge id)(color)

static NSString * const kCAAnimationKeyPathTransform       = @"transform";
static NSString * const kCAAnimationKeyPathBackgroundColor = @"backgroundColor";
static NSString * const kCAAnimationKeyPathZPosition       = @"zPosition";
static NSString * const kGMAnimationKeyFromValue           = @"fromValue";
static NSString * const kGMAnimationKeyToValue             = @"toValue";
static NSString * const kGMAnimationKeyBeginTime           = @"beginTime";
static NSString * const kGMAnimationKeyDuration            = @"duration";

static const CGFloat topZPosition    = 20.0;
static const CGFloat bottomZPosition =  0.0;
static const CFTimeInterval defaultAnimationDuration =  2.0;

@implementation GUIActivityIndicatorView {
    CALayer *_layer1, *_layer2, *_layer3, *_layer4;
    BOOL _animating : 1;
    BOOL _addedAnimations : 1;
}

- (void)_commonInit
{
    NSSize size = self.bounds.size;
    self.wantsLayer = YES;
    
    _layer1 = [self _halfCircleLayerForSize:size];
    [self.layer addSublayer:_layer1];
    _layer2 = [self _halfCircleLayerForSize:size];
    [self.layer addSublayer:_layer2];
    _layer3 = [self _halfCircleLayerForSize:size];
    [self.layer addSublayer:_layer3];
    _layer4 = [self _halfCircleLayerForSize:size];
    [self.layer addSublayer:_layer4];
    
    _layer1.backgroundColor = DARK_BLUE();
    _layer2.backgroundColor = DARK_BLUE();
    _layer2.transform = CATransform3DMakeScale(1, -1, 1);
    
    for (CALayer *layer in self.layer.sublayers) {
        layer.doubleSided = NO;
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self _commonInit];
    }
    return self;
}

- (void)_setAnimating:(BOOL)animating
{
    [self willChangeValueForKey:@"animating"];
    _animating = animating;
    [self didChangeValueForKey:@"animating"];
}

- (void)startAnimating
{
    if (!_animating) {
        [self _setAnimating:YES];
        if (_addedAnimations) {
            [self _resumeLayers];
        } else {
            [self _resumeLayers];
            [self _addAnimations];
        }
    }
}

- (void)_addAnimations
{
    [CATransaction begin];
    
    NSArray *animations = @[[self _layer1AnimationWithTotalDuration:defaultAnimationDuration],
                            [self _layer2AnimationWithTotalDuration:defaultAnimationDuration],
                            [self _layer3AnimationWithTotalDuration:defaultAnimationDuration],
                            [self _layer4AnimationWithTotalDuration:defaultAnimationDuration]];
    
    NSArray *layers = [self _layers];
    
    for (NSUInteger i = 0; i < animations.count; ++i) {
        CAAnimation *animation = animations[i];
        CALayer *layer         = layers[i];
        animation.repeatCount  = HUGE_VALF;
        [layer addAnimation:animation forKey:[NSUUID UUID].UUIDString];
    }
    
    _addedAnimations = YES;
    
    [CATransaction commit];
}

- (void)setHidden:(BOOL)hidden
{
    if (self.hidden != hidden) {
        [super setHidden:hidden];
        // all animations are removed when the view is hidden
        if (hidden) {
            _addedAnimations = NO;
        } else if (_animating) {
            // in case we're animating, make sure
            // we resume correctly
            _animating = NO;
            _addedAnimations = NO;
            [self startAnimating];
        }
    }
}

- (void)stopAnimating
{
    NSButton *button;
    [button setEnabled:YES];
    if (_animating) {
        [self _setAnimating:NO];
        if (_hidesWhenStopped) {
            self.hidden = YES;
        }
        [self _pauseLayers];
    }
}

- (void)_pauseLayers
{
    [CATransaction begin];
    
    for (CALayer *layer in [self _layers]) {
        CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
    
    [CATransaction commit];
}

- (void)_resumeLayers
{
    [CATransaction begin];
    
    for (CALayer *layer in [self _layers]) {
        CFTimeInterval pausedTime = [layer timeOffset];
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        layer.beginTime = timeSincePause;
    }
    
    [CATransaction commit];
}

- (BOOL)isAnimating
{
    return _animating;
}

- (NSArray *)_layers
{
    return @[_layer1, _layer2, _layer3, _layer4];
}

- (CALayer *)_halfCircleLayerForSize:(CGSize)size {
    CGFloat radius = size.width / 2;
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, size.width, size.height);
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGPathMoveToPoint(mutablePath, NULL, 0, size.height / 2);
    CGPathAddArc(mutablePath, NULL, radius, radius, radius, 0, M_PI, false);
    
    shapeLayer.path = mutablePath;
    
    layer.mask = shapeLayer;
    layer.cornerRadius = size.width / 2;
    
    return layer;
}

#pragma mark - Animation helpers

- (CAAnimation *)_animationWithValueDescriptions:(NSArray *)valueDescriptions keyPath:(NSString *)keyPath totalDuration:(CFTimeInterval)totalDuration
{
    CAKeyframeAnimation *keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    NSMutableArray *values   = [NSMutableArray array];
    NSMutableArray *keyTimes =  [NSMutableArray array];
    
    CGFloat increment = 1.0 / valueDescriptions.count;
    CGFloat beginKeyTime = 0.0;
    
    for (NSDictionary *valueDescription in valueDescriptions) {
        NSDictionary *animationDescription = valueDescription[keyPath];
        
        [values addObject:animationDescription[kGMAnimationKeyFromValue]];
        [keyTimes addObject:@(beginKeyTime)];
        
        [values addObject:animationDescription[kGMAnimationKeyToValue]];
        beginKeyTime += increment;
        [keyTimes addObject:@(beginKeyTime)];
    }
    
    keyframeAnimation.values   = values;
    keyframeAnimation.keyTimes = keyTimes;
    
    return keyframeAnimation;
}

- (CAAnimation *)_animationWithValueDescriptions:(NSArray *)valueDescriptions totalDuration:(CFTimeInterval)totalDuration
{
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = totalDuration;
    
    CAAnimation *transformAnimation = [self _animationWithValueDescriptions:valueDescriptions
                                                                    keyPath:kCAAnimationKeyPathTransform
                                                              totalDuration:totalDuration];
    
    CAAnimation *backgroundColorAnimation = [self _animationWithValueDescriptions:valueDescriptions
                                                                          keyPath:kCAAnimationKeyPathBackgroundColor
                                                                    totalDuration:totalDuration];
    
    CAAnimation *zPositionAnimation = [self _animationWithValueDescriptions:valueDescriptions
                                                                    keyPath:kCAAnimationKeyPathZPosition
                                                              totalDuration:totalDuration];
    group.animations = @[transformAnimation, backgroundColorAnimation, zPositionAnimation];
    
    return group;
}

- (CAAnimation *)_animationForTransformValues:(NSArray *)transformValues
                        backgroundColorValues:(NSArray *)backgroundColorValues
                              zPositionValues:(NSArray *)zPositionValues
                                totalDuration:(CFTimeInterval)totalDuration
{
    assert(transformValues.count == backgroundColorValues.count && backgroundColorValues.count == zPositionValues.count);
    assert(transformValues.count % 2 == 0);
    
    NSMutableArray *valueDescriptions = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < transformValues.count; i += 2) {
        [valueDescriptions addObject:@{kCAAnimationKeyPathTransform:       @{kGMAnimationKeyFromValue: transformValues[i],
                                                                             kGMAnimationKeyToValue:   transformValues[i+1]},
                                       kCAAnimationKeyPathBackgroundColor: @{kGMAnimationKeyFromValue: backgroundColorValues[i],
                                                                             kGMAnimationKeyToValue:   backgroundColorValues[i+1]},
                                       kCAAnimationKeyPathZPosition:       @{kGMAnimationKeyFromValue: zPositionValues[i],
                                                                             kGMAnimationKeyToValue:   zPositionValues[i+1]}
                                       }];
    }
    
    return [self _animationWithValueDescriptions:valueDescriptions totalDuration:totalDuration];
}

- (CAAnimation *)_animationForTransformValues:(NSArray *)transformValues
                        backgroundColorValues:(NSArray *)backgroundColorValues
                                totalDuration:(CFTimeInterval)totalDuration
{
    NSMutableArray *zPositionValues = [NSMutableArray arrayWithCapacity:transformValues.count];
    for (NSUInteger i = 0; i < transformValues.count; ++i) {
        [zPositionValues addObject:@0.0];
    }
    
    return [self _animationForTransformValues:transformValues
                        backgroundColorValues:backgroundColorValues
                              zPositionValues:zPositionValues
                                totalDuration:totalDuration];
}

#pragma mark - Layer Animations

- (CAAnimation *)_layer1AnimationWithTotalDuration:(CFTimeInterval)totalDuration
{
    CATransform3D transform1 = CATransform3DMakeRotation(M_PI, 0, 0, 1);
    CATransform3D transform2 = CATransform3DMakeRotation(-M_PI_2, 0, 0, 1);
    CATransform3D transform3 = CATransform3DIdentity;
    CATransform3D transform4 = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
    
    CGColorRef color1 = DARK_BLUE();
    CGColorRef color2 = DARK_YELLOW();
    CGColorRef color3 = DARK_YELLOW();
    CGColorRef color4 = DARK_BLUE();
    
    return [self _animationForTransformValues:@[// first animation
                                                TRANSFORM_VALUE(transform1), TRANSFORM_VALUE(transform1),
                                                // second animation
                                                TRANSFORM_VALUE(transform2), TRANSFORM_VALUE(transform2),
                                                // third animation
                                                TRANSFORM_VALUE(transform3), TRANSFORM_VALUE(transform3),
                                                // fourth animation
                                                TRANSFORM_VALUE(transform4), TRANSFORM_VALUE(transform4)]
                        backgroundColorValues:@[// first animation
                                                COLOR_VALUE(color1), COLOR_VALUE(color1),
                                                // second animation
                                                COLOR_VALUE(color2), COLOR_VALUE(color2),
                                                // third animation
                                                COLOR_VALUE(color3), COLOR_VALUE(color3),
                                                // fourth animation
                                                COLOR_VALUE(color4), COLOR_VALUE(color4)
                                                ]
                                totalDuration:totalDuration];
}

- (CAAnimation *)_layer2AnimationWithTotalDuration:(CFTimeInterval)totalDuration
{
    CATransform3D transform1_1 = CATransform3DIdentity;
    CATransform3D transform1_2 = CATransform3DMakeRotation(M_PI, 1, 0, 0);
    
    CATransform3D transform2_1 = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
    transform2_1               = CATransform3DRotate(transform2_1, M_PI, 1, 0, 0);
    CATransform3D transform2_2 = CATransform3DRotate(transform2_1, -M_PI, 1, 0, 0);
    
    CATransform3D transform3_1 = CATransform3DMakeScale(1, -1, 1);
    CATransform3D transform3_2 = CATransform3DRotate(transform3_1, -M_PI, 1, 0, 0);
    
    CATransform3D transform4_1 = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
    transform4_1               = CATransform3DRotate(transform4_1, M_PI, 0, 1, 0);
    CATransform3D transform4_2 = CATransform3DRotate(transform4_1, -M_PI, 1, 0, 0);
    
    CGColorRef color1_1 = DARK_BLUE();
    CGColorRef color1_2 = LIGHT_BLUE();
    CGColorRef color2_1 = LIGHT_YELLOW();
    CGColorRef color2_2 = DARK_YELLOW();
    CGColorRef color3_1 = DARK_YELLOW();
    CGColorRef color3_2 = LIGHT_YELLOW();
    CGColorRef color4_1 = LIGHT_BLUE();
    CGColorRef color4_2 = DARK_BLUE();
    
    return [self _animationForTransformValues:@[// first animation
                                                TRANSFORM_VALUE(transform1_1), TRANSFORM_VALUE(transform1_2),
                                                // second animation
                                                TRANSFORM_VALUE(transform2_1), TRANSFORM_VALUE(transform2_2),
                                                // third animation
                                                TRANSFORM_VALUE(transform3_1), TRANSFORM_VALUE(transform3_2),
                                                // fourth animation
                                                TRANSFORM_VALUE(transform4_1), TRANSFORM_VALUE(transform4_2)]
                        backgroundColorValues:@[// first animation
                                                COLOR_VALUE(color1_1), COLOR_VALUE(color1_2),
                                                // second animation
                                                COLOR_VALUE(color2_1), COLOR_VALUE(color2_2),
                                                // third animation
                                                COLOR_VALUE(color3_1), COLOR_VALUE(color3_2),
                                                // fourth animation
                                                COLOR_VALUE(color4_1), COLOR_VALUE(color4_2)]
                              zPositionValues:@[// first animation
                                                @(topZPosition), @(topZPosition),
                                                // second animation
                                                @(topZPosition), @(topZPosition),
                                                // third animation
                                                @(topZPosition), @(topZPosition),
                                                // fourth animation
                                                @(bottomZPosition), @(bottomZPosition)]
                                totalDuration:totalDuration];
}

- (CAAnimation *)_layer3AnimationWithTotalDuration:(CFTimeInterval)totalDuration
{
    CATransform3D transform1_1 = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    CATransform3D transform1_2 = CATransform3DRotate(transform1_1, -M_PI, 1, 0, 0);
    
    CATransform3D transform2_1 = CATransform3DMakeRotation(-M_PI_2, 0, 0, 1);
    CATransform3D transform2_2 = CATransform3DRotate(transform2_1, M_PI, 1, 0, 0);
    
    CATransform3D transform3_1 = CATransform3DMakeScale(1, -1, 1);
    transform3_1               = CATransform3DRotate(transform3_1, M_PI, 0, 1, 0);
    CATransform3D transform3_2 = CATransform3DRotate(transform3_1, M_PI, 1, 0, 0);
    
    CATransform3D transform4_1 = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
    CATransform3D transform4_2 = CATransform3DRotate(transform4_1, M_PI, 1, 0, 0);
    
    CGColorRef color1_1 = DARK_RED();
    CGColorRef color1_2 = LIGHT_RED();
    CGColorRef color2_1 = LIGHT_RED();
    CGColorRef color2_2 = DARK_RED();
    CGColorRef color3_1 = DARK_GREEN();
    CGColorRef color3_2 = LIGHT_GREEN();
    CGColorRef color4_1 = LIGHT_GREEN();
    CGColorRef color4_2 = LIGHT_GREEN();
    
    return [self _animationForTransformValues:@[// first animation
                                                TRANSFORM_VALUE(transform1_1), TRANSFORM_VALUE(transform1_2),
                                                // second animation
                                                TRANSFORM_VALUE(transform2_1), TRANSFORM_VALUE(transform2_2),
                                                // third animation
                                                TRANSFORM_VALUE(transform3_1), TRANSFORM_VALUE(transform3_2),
                                                // fourth animation
                                                TRANSFORM_VALUE(transform4_1), TRANSFORM_VALUE(transform4_2)]
                        backgroundColorValues:@[// first animation
                                                COLOR_VALUE(color1_1), COLOR_VALUE(color1_2),
                                                // second animation
                                                COLOR_VALUE(color2_1), COLOR_VALUE(color2_2),
                                                // third animation
                                                COLOR_VALUE(color3_1), COLOR_VALUE(color3_2),
                                                // fourth animation
                                                COLOR_VALUE(color4_1), COLOR_VALUE(color4_2)]
                              zPositionValues:@[// first animation
                                                @(bottomZPosition), @(bottomZPosition),
                                                // second animation
                                                @(bottomZPosition), @(bottomZPosition),
                                                // third animation
                                                @(bottomZPosition), @(bottomZPosition),
                                                // fourth animation
                                                @(topZPosition), @(topZPosition)]
                                totalDuration:totalDuration];
}

- (CAAnimation *)_layer4AnimationWithTotalDuration:(CFTimeInterval)totalDuration
{
    CATransform3D transform1 = CATransform3DIdentity;
    CATransform3D transform2 = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
    CATransform3D transform3 = CATransform3DMakeScale(1, -1, 1);
    CATransform3D transform4 = CATransform3DMakeRotation(-M_PI_2, 0, 0, 1);
    
    CGColorRef color1 = LIGHT_RED();
    CGColorRef color2 = LIGHT_RED();
    CGColorRef color3 = LIGHT_GREEN();
    CGColorRef color4 = LIGHT_GREEN();
    
    return [self _animationForTransformValues:@[// first animation
                                                TRANSFORM_VALUE(transform1), TRANSFORM_VALUE(transform1),
                                                // second animation
                                                TRANSFORM_VALUE(transform2), TRANSFORM_VALUE(transform2),
                                                // third animation
                                                TRANSFORM_VALUE(transform3), TRANSFORM_VALUE(transform3),
                                                // fourth animation
                                                TRANSFORM_VALUE(transform4), TRANSFORM_VALUE(transform4)]
                        backgroundColorValues:@[// first animation
                                                COLOR_VALUE(color1), COLOR_VALUE(color1),
                                                // second animation
                                                COLOR_VALUE(color2), COLOR_VALUE(color2),
                                                // third animation
                                                COLOR_VALUE(color3), COLOR_VALUE(color3),
                                                // fourth animation
                                                COLOR_VALUE(color4), COLOR_VALUE(color4)]
                                totalDuration:totalDuration];
}

@end
