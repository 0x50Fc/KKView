//
//  KKPixel.h
//  KKView
//
//  Created by hailong11 on 2017/12/25.
//  Copyright © 2017年 mofang.cn. All rights reserved.
//

#import <UIKit/UIKit.h>

enum KKPixelType {
    KKPixelTypeAuto,KKPixelTypePercent,KKPixelTypePX,KKPixelTypeRPX
};

struct KKPixel {
    CGFloat value;
    enum KKPixelType type;
};

struct KKEdge {
    struct KKPixel top,right,bottom,left;
};

extern struct KKPixel KKPixelFromString(NSString * value);

extern struct KKEdge KKEdgeFromString(NSString * value);

extern CGFloat KKPixelUnitPX(void);
extern CGFloat KKPixelUnitRPX(void);

extern CGFloat KKPixelValue(struct KKPixel v ,CGFloat baseOf,CGFloat defaultValue);

extern NSString * KKStringValue(id value);

extern BOOL KKBooleanValue(id value);
