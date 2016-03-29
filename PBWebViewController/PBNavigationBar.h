//
//  PBNavigationBar.h
//  Example
//
//  Created by guoshencheng on 3/29/16.
//  Copyright © 2016 Mikael Konutgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PBNavigationBarDelegate;

@interface PBNavigationBar : UIView

@property (strong, nonatomic) NSString *title;
@property (weak, nonatomic) id<PBNavigationBarDelegate> delegate;

+ (instancetype)create;
- (void)setLeftButtonImage:(UIImage *)image forState:(UIControlState)state;

@end

@protocol PBNavigationBarDelegate <NSObject>
@optional
- (void)navigationBarDidClickLeftButton:(PBNavigationBar *)navigationBar;

@end
