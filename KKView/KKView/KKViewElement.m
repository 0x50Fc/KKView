//
//  KKViewElement.m
//  KKView
//
//  Created by hailong11 on 2017/12/25.
//  Copyright © 2017年 mofang.cn. All rights reserved.
//

#import "KKViewElement.h"

#import "UIColor+KKElement.h"
#import "UIFont+KKElement.h"
#import "KKPixel.h"

#include <objc/runtime.h>

@implementation KKViewElement


-(void) changedKey:(NSString *) key {
    [super changedKey:key];
    
    NSString * value = [self get:key];
    
    if([key isEqualToString:@"padding"]) {
        _padding = KKEdgeFromString(value);
    } else if([key isEqualToString:@"margin"]) {
        _margin = KKEdgeFromString(value);
    } else if([key isEqualToString:@"width"]) {
        _width = KKPixelFromString(value);
    } else if([key isEqualToString:@"min-width"]) {
        _minWidth = KKPixelFromString(value);
    } else if([key isEqualToString:@"max-width"]) {
        _maxWidth = KKPixelFromString(value);
    } else if([key isEqualToString:@"height"]) {
        _height = KKPixelFromString(value);
    } else if([key isEqualToString:@"min-height"]) {
        _minHeight = KKPixelFromString(value);
    } else if([key isEqualToString:@"max-height"]) {
        _maxHeight = KKPixelFromString(value);
    } else if([key isEqualToString:@"left"]) {
        _left = KKPixelFromString(value);
    } else if([key isEqualToString:@"right"]) {
        _right = KKPixelFromString(value);
    } else if([key isEqualToString:@"top"]) {
        _top = KKPixelFromString(value);
    } else if([key isEqualToString:@"bottom"]) {
        _bottom = KKPixelFromString(value);
    } else if([key isEqualToString:@"layout"]) {
        if([value isEqualToString:@"relative"]) {
            [self setLayout: KKViewElementLayoutRelative];
        } else if([value isEqualToString:@"flex"]) {
            [self setLayout: KKViewElementLayoutFlex];
        } else if([value isEqualToString:@"horizontal"]) {
            [self setLayout: KKViewElementLayoutHorizontal];
        } else {
            [self setLayout: NULL];
        }
    }
    [_view KKViewElement:self setProperty:key value:value];
}

#define KKViewDequeueViewsKey  "KKViewDequeueViewsKey"

-(NSString *) reuse {
    return [self get:@"reuse"];
}

-(Class) viewClass {
    return NSClassFromString([self get:@"view"]);
}

-(void) obtainView:(UIView *) view {
    
    if(_view && _view.superview == view) {
        [self obtainChildrenView];
        return;
    }
    
    [self recycleView];
    
    __strong UIView * vv = nil;
    
    UIView * v = view;
    
    NSString * reuse = self.reuse;
    
    if([reuse length] > 0) {
        
        NSMutableDictionary * dequeueViews = objc_getAssociatedObject(v, KKViewDequeueViewsKey);
        
        if(dequeueViews != nil) {
            
            NSMutableArray * views = [dequeueViews objectForKey:reuse];
            
            if([views count] > 0) {
                
                vv = [views lastObject];
                
                [views removeLastObject];
                
                [v addSubview:vv];
                
            }
            
        }
    }
    
    if(vv == nil) {
        vv = [[[self viewClass] alloc] initWithFrame:CGRectZero];
    }
    
    if(vv == nil) {
        vv = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    [v addSubview:vv];
    
    [vv KKElementObtainView:self];

    [self setView:vv];
    
    [self changedKeys:[self keys]];
    
    [vv KKViewElementDidLayouted:self];
    
    [self obtainChildrenView];
}

-(void) recycleView {
    
    UIView * vv = _view;
    UIView * v = [vv superview];
    
    if(v) {
        
        NSString * reuse = self.reuse;

        if([reuse length] > 0) {

            NSMutableDictionary * dequeueViews = objc_getAssociatedObject(v, KKViewDequeueViewsKey);
            
            if(dequeueViews == nil) {
                dequeueViews = [NSMutableDictionary dictionaryWithCapacity:4];
                objc_setAssociatedObject(v, KKViewDequeueViewsKey, dequeueViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            
            NSMutableArray * views = [dequeueViews objectForKey:reuse];
            
            if(views == nil) {
                views = [NSMutableArray arrayWithCapacity:4];
                [dequeueViews setObject:views forKey:reuse];
            }
            
            [views addObject:vv];
            
        }
        
        [vv KKElementRecycleView:self];
        
        [vv removeFromSuperview];
        
        [vv KKElementRecycleView:self];
        
        [self setView:nil];
    }
}

-(void) obtainChildrenView {
    
    if(_view) {
        
        KKElement * p = self.firstChild;
        
        while(p) {
            
            if([p isKindOfClass:[KKViewElement class]]) {
                KKViewElement * e = (KKViewElement *) p;
                if([self isChildrenVisible:e]) {
                    [e obtainView:_view];
                } else {
                    [e recycleView];
                }
            }
            p = p.nextSibling;
        }
    }
    

}

-(void) didAddChildren:(KKElement *)element {
    [super didAddChildren:element];
}

-(void) remove {
    [self recycleView];
    [super remove];
}

-(BOOL) isChildrenVisible:(KKViewElement *) element {
    CGRect r = _frame;
    r.origin = _contentOffset;
    return CGRectIntersectsRect(r, element.frame);
}

-(BOOL) isHidden {
    NSString * v = [self get:@"hidden"];
    return v == nil ? false: KKBooleanValue(v);
}


-(void) layoutChildren {
    if(_layout) {
        _contentSize = (* _layout)(self);
    }
}

-(void) layout:(CGSize) size {
    _frame.size = size;
    if(_layout) {
        _contentSize = (* _layout)(self);
    }
    [self didLayouted];
}

-(void) didLayouted {
    [_view KKViewElementDidLayouted:self];
    [self obtainChildrenView];
}

-(void) setContentOffset:(CGPoint)contentOffset {
    _contentOffset = contentOffset;
    [self obtainChildrenView];
}

-(void) changedKeys:(NSSet *)keys {
    [super changedKeys:keys];
    if(_view) {
        for(NSString * key in keys) {
            [_view KKViewElement:self setProperty:key value:[self get:key]];
        }
    }
}

@end

/**
 * 相对布局 "relative"
 */
CGSize KKViewElementLayoutRelative(KKViewElement * element) {
    
    CGSize size = element.frame.size;
    struct KKEdge padding = element.padding;
    CGFloat paddingLeft = KKPixelValue(padding.left, size.width, 0);
    CGFloat paddingRight = KKPixelValue(padding.right, size.width, 0);
    CGFloat paddingTop = KKPixelValue(padding.top, size.height, 0);
    CGFloat paddingBottom = KKPixelValue(padding.bottom, size.height, 0);
    CGSize inSize = CGSizeMake(size.width - paddingLeft - paddingRight,size.height - paddingTop - paddingBottom);
    
    CGSize contentSize = CGSizeZero;
    
    KKElement * p = element.firstChild;
    
    while(p) {
        
        if([p isKindOfClass:[KKViewElement class]]) {
            
            KKViewElement * e = (KKViewElement *) p;
            
            CGFloat mleft = KKPixelValue(e.margin.left, inSize.width, 0);
            CGFloat mright = KKPixelValue(e.margin.right, inSize.width, 0);
            CGFloat mtop = KKPixelValue(e.margin.top, inSize.height, 0);
            CGFloat mbottom = KKPixelValue(e.margin.bottom, inSize.height, 0);
            
            CGFloat width = KKPixelValue(e.width, inSize.width - mleft - mright, MAXFLOAT);
            CGFloat height = KKPixelValue(e.height, inSize.height - mtop - mbottom, MAXFLOAT);
            
            CGRect v = e.frame;
            
            v.size.width = width;
            v.size.height = height;
            
            e.frame = v;
            
            [e layoutChildren];
            
            if(width == MAXFLOAT) {
                width = v.size.width = e.contentSize.width;
                CGFloat min = KKPixelValue(e.minWidth, inSize.width, 0);
                CGFloat max = KKPixelValue(e.maxWidth, inSize.width, MAXFLOAT);
                if(v.size.width < min) {
                    width = v.size.width = min;
                }
                if(v.size.width > max) {
                    width = v.size.width = max;
                }
            }
            
            if(height == MAXFLOAT) {
                height = v.size.height = e.contentSize.height;
                CGFloat min = KKPixelValue(e.minHeight, inSize.height, 0);
                CGFloat max = KKPixelValue(e.maxHeight, inSize.height, MAXFLOAT);
                if(v.size.height < min) {
                    height = v.size.height = min;
                }
                if(v.size.height > max) {
                    height = v.size.height = max;
                }
            }
            
            e.frame = v;
            
            CGFloat left = KKPixelValue(e.left, inSize.width, MAXFLOAT);
            CGFloat right = KKPixelValue(e.right, inSize.width, MAXFLOAT);
            CGFloat top = KKPixelValue(e.top, inSize.height, MAXFLOAT);
            CGFloat bottom = KKPixelValue(e.bottom, inSize.height, MAXFLOAT);
            
            if(left == MAXFLOAT) {
                
                if(size.width == MAXFLOAT) {
                    left = paddingLeft + mleft;
                } else if(right == MAXFLOAT) {
                    left = paddingLeft + mleft + (inSize.width - width - mleft - mright) * 0.5f;
                } else {
                    left = paddingLeft + (inSize.width - right - mright - width);
                }
                
            } else {
                left = paddingLeft + left;
            }
            
            if(top == MAXFLOAT) {
                
                if(size.height == MAXFLOAT) {
                    top = paddingTop + mtop;
                } else if(bottom == MAXFLOAT) {
                    top = paddingTop + mtop + (inSize.height - height - mtop - mbottom) * 0.5f;
                } else {
                    top = paddingTop + (inSize.height - height - mbottom );
                }
                
            } else {
                top = paddingTop + top + mtop;
            }
            
            v = e.frame;
            
            v.origin.x = left ;
            v.origin.y = top ;
            
            if(left + paddingRight + mright + v.size.width > contentSize.width) {
                contentSize.width = left + paddingRight + mright + v.size.width;
            }
            
            if(top + paddingBottom + mbottom  + v.size.height > contentSize.height) {
                contentSize.height = top + paddingBottom + mbottom + v.size.height ;
            }
            
            e.frame = v;
            [e didLayouted];
        }
        
        p = p.nextSibling;
    }
    
    return contentSize;
}

/**
 * 流式布局 "flex" 左到右 上到下
 */
CGSize KKViewElementLayoutFlex(KKViewElement * element) {
    
    CGSize size = element.frame.size;
    struct KKEdge padding = element.padding;
    CGFloat paddingLeft = KKPixelValue(padding.left, size.width, 0);
    CGFloat paddingRight = KKPixelValue(padding.right, size.width, 0);
    CGFloat paddingTop = KKPixelValue(padding.top, size.height, 0);
    CGFloat paddingBottom = KKPixelValue(padding.bottom, size.height, 0);
    CGSize inSize = CGSizeMake(size.width - paddingLeft - paddingRight,size.height - paddingTop - paddingBottom);
    
    CGFloat y = paddingTop;
    CGFloat x = paddingLeft;
    CGFloat maxWidth = paddingLeft + paddingRight;
    CGFloat lineHeight = 0;
    
    KKElement * p = element.firstChild;
    
    while(p) {
        
        if([p isKindOfClass:[KKViewElement class]]) {
            
            KKViewElement * e = (KKViewElement *) p;
            
            if([e isHidden]) {
                continue;
            }
            
            CGFloat width = KKPixelValue(e.width, inSize.width, MAXFLOAT);
            CGFloat height = KKPixelValue(e.height, inSize.height, MAXFLOAT);
            
            CGRect v = e.frame;
            
            v.size.width = width;
            v.size.height = height;
            
            e.frame = v;
            
            [e layoutChildren];
            
            if(width == MAXFLOAT) {
                width = v.size.width = e.contentSize.width;
                CGFloat min = KKPixelValue(e.minWidth, inSize.width, 0);
                CGFloat max = KKPixelValue(e.maxWidth, inSize.width, MAXFLOAT);
                if(v.size.width < min) {
                    width = v.size.width = min;
                }
                if(v.size.width > max) {
                    width = v.size.width = max;
                }
            }
            
            if(height == MAXFLOAT) {
                height = v.size.height = e.contentSize.height;
                CGFloat min = KKPixelValue(e.minHeight, inSize.height, 0);
                CGFloat max = KKPixelValue(e.maxHeight, inSize.height, MAXFLOAT);
                if(v.size.height < min) {
                    height = v.size.height = min;
                }
                if(v.size.height > max) {
                    height = v.size.height = max;
                }
            }
            
            e.frame = v;
            
            CGFloat mleft = KKPixelValue(e.margin.left, inSize.width, 0);
            CGFloat mright = KKPixelValue(e.margin.right, inSize.width, 0);
            CGFloat mtop = KKPixelValue(e.margin.top, inSize.height, 0);
            CGFloat mbottom = KKPixelValue(e.margin.bottom, inSize.height, 0);
            
            if(x + mleft + mright + paddingRight >= size.width) {
                y += lineHeight;
                lineHeight = 0;
                x = paddingLeft;
            }
            
            CGFloat left = x + mleft;
            CGFloat top = y + mtop;
            
            x += width + mleft + mright;
            
            if(lineHeight < height + mtop + mbottom) {
                lineHeight = height + mtop + mbottom;
            }
            
            v = e.frame;
            
            v.origin.x = left;
            v.origin.y = top;
            
            if(left + paddingRight + mright > maxWidth) {
                maxWidth = left + paddingRight + mright;
            }
            
            e.frame = v;
            [e didLayouted];
        }
        
        p = p.nextSibling;
    }
    
    return CGSizeMake(maxWidth,y + lineHeight + paddingBottom);
}

/**
 * 水平布局 "horizontal" 左到右
 */
CGSize KKViewElementLayoutHorizontal(KKViewElement * element) {
    CGSize size = element.frame.size;
    struct KKEdge padding = element.padding;
    CGFloat paddingLeft = KKPixelValue(padding.left, size.width, 0);
    CGFloat paddingRight = KKPixelValue(padding.right, size.width, 0);
    CGFloat paddingTop = KKPixelValue(padding.top, size.height, 0);
    CGFloat paddingBottom = KKPixelValue(padding.bottom, size.height, 0);
    CGSize inSize = CGSizeMake(size.width - paddingLeft - paddingRight,size.height - paddingTop - paddingBottom);
    
    CGFloat y = paddingTop;
    CGFloat x = paddingLeft;
    CGFloat maxWidth = paddingLeft + paddingRight;
    CGFloat lineHeight = 0;
    
    KKElement * p = element.firstChild;
    
    while(p) {

        if([p isKindOfClass:[KKViewElement class]]) {
            
            KKViewElement * e = (KKViewElement *) p;
            
            CGFloat width = KKPixelValue(e.width, inSize.width, MAXFLOAT);
            CGFloat height = KKPixelValue(e.height, inSize.height, MAXFLOAT);
            
            CGRect v = e.frame;
            
            v.size.width = width;
            v.size.height = height;
            
            e.frame = v;
            
            [e layoutChildren];
            
            if(width == MAXFLOAT) {
                width = v.size.width = e.contentSize.width;
                CGFloat min = KKPixelValue(e.minWidth, inSize.width, 0);
                CGFloat max = KKPixelValue(e.maxWidth, inSize.width, MAXFLOAT);
                if(v.size.width < min) {
                    width = v.size.width = min;
                }
                if(v.size.width > max) {
                    width = v.size.width = max;
                }
            }
            
            if(height == MAXFLOAT) {
                height = v.size.height = e.contentSize.height;
                CGFloat min = KKPixelValue(e.minHeight, inSize.height, 0);
                CGFloat max = KKPixelValue(e.maxHeight, inSize.height, MAXFLOAT);
                if(v.size.height < min) {
                    height = v.size.height = min;
                }
                if(v.size.height > max) {
                    height = v.size.height = max;
                }
            }
            
            e.frame = v;
            
            CGFloat mleft = KKPixelValue(e.margin.left, inSize.width, 0);
            CGFloat mright = KKPixelValue(e.margin.right, inSize.width, 0);
            CGFloat mtop = KKPixelValue(e.margin.top, inSize.height, 0);
            CGFloat mbottom = KKPixelValue(e.margin.bottom, inSize.height, 0);
            
            CGFloat left = x + mleft;
            CGFloat top = y + mtop;
            
            x += width + mleft + mright;
            
            if(lineHeight < height + mtop + mbottom) {
                lineHeight = height + mtop + mbottom;
            }
            
            v = e.frame;
            
            v.origin.x = left ;
            v.origin.y = top ;
            
           
            if(left + paddingRight + mright > maxWidth) {
                maxWidth = left + paddingRight + mright;
            }
            
            e.frame = v;
            [e didLayouted];
        }
        
        p = p.nextSibling;
    }
    
    return CGSizeMake(maxWidth,y + lineHeight + paddingBottom);
}

@implementation UIView (KKElement)

-(void) KKViewElement:(KKViewElement *) element setProperty:(NSString *) key value:(NSString *) value {
    if([key isEqualToString:@"background-color"]) {
        self.backgroundColor = [UIColor KKElementStringValue:value];
    } else if([key isEqualToString:@"border-color"]) {
        self.layer.borderColor = [UIColor KKElementStringValue:value].CGColor;
    } else if([key isEqualToString:@"border-width"]) {
        self.layer.borderWidth = KKPixelValue(KKPixelFromString(value), element.frame.size.width, 0);
    } else if([key isEqualToString:@"border-radius"]) {
        self.layer.cornerRadius = KKPixelValue(KKPixelFromString(value), element.frame.size.width, 0);
    } else if([key isEqualToString:@"opacity"]) {
        self.alpha = value == nil || [value isEqualToString:@""] ? 1.0 : [value doubleValue];
    } else if([key isEqualToString:@"hidden"]) {
        self.hidden = value == nil ? false: KKBooleanValue(value);
    } else if([key isEqualToString:@"overflow"]) {
        if([@"hidden" isEqualToString:value]) {
            self.layer.masksToBounds = YES;
        } else {
            self.layer.masksToBounds = NO;
        }
    }
}

-(void) KKViewElementDidLayouted:(KKViewElement *) element {
    self.frame = element.frame;
}

-(void) KKElementRecycleView:(KKViewElement *) element {
    
}

-(void) KKElementObtainView:(KKViewElement *) element {
    
}

@end

@implementation UIScrollView (KKElement)

-(void) KKViewElement:(KKViewElement *) element setProperty:(NSString *) key value:(NSString *) value {
    [super KKViewElement:element setProperty:key value:value];
}

-(void) KKViewElementDidLayouted:(KKViewElement *) element {
    [super KKViewElementDidLayouted:element];
    
    CGSize size = element.contentSize;
    
    if([[element get:@"overflow-y"] isEqualToString:@"scroll"]) {
        size.height = MAX(element.frame.size.height + 1,size.height);
    }
    
    if([[element get:@"overflow-x"] isEqualToString:@"scroll"]) {
        size.width = MAX(element.frame.size.width + 1,size.width);
    }
    
    self.contentSize = size;
}

@end

