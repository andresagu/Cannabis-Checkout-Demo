//
//  AppDelegate.h
//  mpopGroceryDemo
//
//  Created by Andres Aguaiza on 3/29/19.
//  Copyright © 2019 Andres Aguaiza. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <StarIO_Extension/StarIoExt.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSString *)getPortName;

+ (void)setPortName:(NSString *)portName;

+ (NSString *)getPortSettings;

+ (void)setPortSettings:(NSString *)portSettings;

+ (NSString *)getModelName;

+ (void)setModelName:(NSString *)modelName;

//+ (NSString *)getMacAddress;

//+ (void)setMacAddress:(NSString *)macAddress;

+ (StarIoExtEmulation)getEmulation;

+ (void)setEmulation:(StarIoExtEmulation)emulation;

+ (BOOL)getCashDrawerOpenActiveHigh;

+ (void)setCashDrawerOpenActiveHigh:(BOOL)activeHigh;

@end

