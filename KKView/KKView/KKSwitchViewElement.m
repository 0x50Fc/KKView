//
//  KKSwitchViewElement.m
//  KKView
//
//  Created by zhanghailong on 2017/12/29.
//  Copyright © 2017年 mofang.cn. All rights reserved.
//

#import "KKSwitchViewElement.h"
#import "KKViewContext.h"

@implementation KKSwitchViewElement

+(void) initialize{
    
    [KKViewContext setDefaultElementClass:[KKSwitchViewElement class] name:@"switch"];
}

-(instancetype) init {
    if((self = [super init])) {
    }
    return self;
}

-(Class) viewClass {
    return [UISwitch class];
}

-(void) setView:(UIView *)view {
    [(UISwitch *) self.view removeTarget:self action:@selector(doChangeAction:) forControlEvents:UIControlEventValueChanged];
    [super setView:view];
    [(UISwitch *) self.view addTarget:self action:@selector(doChangeAction:) forControlEvents:UIControlEventValueChanged];
}

-(void) doChangeAction:(UISwitch *) view {
    
    KKElementEvent * e = [[KKElementEvent alloc] initWithElement:self];
    
    e.data = [self data];
    
    [self emit:@"change" event:e];
    
}

@end


@implementation UISwitch (KKElement)

-(void) KKViewElement:(KKViewElement *) element setProperty:(NSString *) key value:(NSString *) value {
    [super KKViewElement:element setProperty:key value:value];
    
    if([@"checked" isEqualToString:key]) {
        [self setOn:KKBooleanValue(value)];
    }
}

@end
