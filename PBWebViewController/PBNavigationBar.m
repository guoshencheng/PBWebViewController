//
//  PBNavigationBar.m
//  Example
//
//  Created by guoshencheng on 3/29/16.
//  Copyright © 2016 Mikael Konutgan. All rights reserved.
//

#import "PBNavigationBar.h"

@interface PBNavigationBar ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;

@end

@implementation PBNavigationBar

+ (instancetype)create {
    PBNavigationBar *navigationBar = [[[NSBundle mainBundle] loadNibNamed:@"PBNavigationBar" owner:nil options:nil] lastObject];
    return navigationBar;
}

- (IBAction)didClickLeftButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(navigationBarDidClickLeftButton:)]) {
        [self.delegate navigationBarDidClickLeftButton:self];
    }
}

- (void)setLeftButtonImage:(UIImage *)image forState:(UIControlState)state {
    [self.leftButton setImage:image forState:state];
}

- (void)setTitle:(NSString *)title {
    self.label.text = title;
}

- (NSString *)titles {
    return self.label.text;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self addGradientMask];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:2];
    self.layer.masksToBounds = false;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowPath = shadowPath.CGPath;
}

- (void)addGradientMask {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 15, [UIScreen mainScreen].bounds.size.width, 45);
    gradientLayer.colors =  @[(id)[[UIColor colorWithWhite:0.95f alpha:1.f] CGColor], (id)[[UIColor colorWithWhite:0.95f alpha:0.0f] CGColor]];
    gradientLayer.locations = @[@0.0, @0.5, @1.0];
    gradientLayer.startPoint = CGPointMake(0.5f, 1.0f);
    gradientLayer.endPoint = CGPointMake(0.5f, 0.0f);
    [self.layer insertSublayer:gradientLayer atIndex:0];
}

@end
