//
//  UIView+BackgroundImage.m
//  KKView
//
//  Created by zhanghailong on 2018/1/15.
//  Copyright © 2018年 kkmofang.cn. All rights reserved.
//

#import "UIView+BackgroundImage.h"
#include <objc/runtime.h>

@implementation UIView (BackgroundImage)

-(UIImage *) kk_backgroundImage {
    CGImageRef v = (__bridge CGImageRef) self.layer.contents;
    if(v != nil) {
        return [UIImage imageWithCGImage:v];
    }
    return nil;
}

-(void) setKk_backgroundImage:(UIImage *)kk_backgroundImage {
    
    self.layer.contents = (id) [kk_backgroundImage CGImage];
    
    if(kk_backgroundImage) {
        CGSize size = kk_backgroundImage.size;
        UIEdgeInsets cap = kk_backgroundImage.capInsets;
        if(UIEdgeInsetsEqualToEdgeInsets(cap, UIEdgeInsetsZero)) {
            self.layer.contentsCenter = CGRectMake(0, 0, 1, 1);
            self.layer.contentsScale = [kk_backgroundImage scale];
        } else {
            CGFloat dx = 1.0f / size.width;
            CGFloat dy = 1.0f / size.height;
            CGFloat l = cap.left / size.width;
            CGFloat t = cap.top / size.height;
            CGFloat r = cap.right / size.width;
            CGFloat b = cap.bottom / size.height;
            if(r > 0.0f) {
                dx = r- l;
            }
            if(b > 0.0f) {
                dy = b - t;
            }
            self.layer.contentsCenter = CGRectMake(l,t,dx, dy);
            self.layer.contentsScale = [kk_backgroundImage scale];
        }
    } else {
        self.layer.contentsCenter = CGRectMake(0, 0, 1, 1);
    }
    
}

@end
