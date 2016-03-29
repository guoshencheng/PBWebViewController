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

@end
