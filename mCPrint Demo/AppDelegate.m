//
//  AppDelegate.m
//  mpopGroceryDemo
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (nonatomic, copy) NSString *portName;
@property (nonatomic, copy) NSString *portSettings;
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic, copy) NSString *macAddress;

@property (nonatomic) StarIoExtEmulation emulation;
@property (nonatomic) BOOL               cashDrawerOpenActiveHigh;
@property (nonatomic) NSInteger          selectedIndex;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self loadParam];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)loadParam {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObject:@"BT:mPOP"                           forKey:@"portName"]];
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObject:@""                           forKey:@"portSettings"]];
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObject:@""                           forKey:@"modelName"]];
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObject:@""                           forKey:@"macAddress"]];
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObject:@(StarIoExtEmulationStarPRNT) forKey:@"emulation"]];
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObject:@YES                          forKey:@"cashDrawerOpenActiveHigh"]];
    
    _portName                 = [userDefaults stringForKey :@"portName"];
    _portSettings             = [userDefaults stringForKey :@"portSettings"];
    _modelName                = [userDefaults stringForKey :@"modelName"];
    _macAddress               = [userDefaults stringForKey :@"macAddress"];
    _emulation                = [userDefaults integerForKey:@"emulation"];
    _cashDrawerOpenActiveHigh = [userDefaults boolForKey   :@"cashDrawerOpenActiveHigh"];
}

+ (NSString *)getPortName {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.portName;
}

+ (void)setPortName:(NSString *)portName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.portName = portName;
    
    [userDefaults setObject:delegate.portName forKey:@"portName"];
    
    [userDefaults synchronize];
}

+ (NSString*)getPortSettings {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.portSettings;
}

+ (void)setPortSettings:(NSString *)portSettings {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.portSettings = portSettings;
    
    [userDefaults setObject :delegate.portSettings forKey:@"portSettings"];
    
    [userDefaults synchronize];
}

+ (NSString *)getModelName {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.modelName;
}

+ (void)setModelName:(NSString *)modelName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.modelName = modelName;
    
    [userDefaults setObject:delegate.modelName forKey:@"modelName"];
    
    [userDefaults synchronize];
}

+ (NSString *)getMacAddress {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.macAddress;
}

+ (void)setMacAddress:(NSString *)macAddress {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.macAddress = macAddress;
    
    [userDefaults setObject:delegate.macAddress forKey:@"macAddress"];
    
    [userDefaults synchronize];
}

+ (StarIoExtEmulation)getEmulation {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.emulation;
}

+ (void)setEmulation:(StarIoExtEmulation)emulation {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.emulation = emulation;
    
    [userDefaults setInteger:delegate.emulation forKey:@"emulation"];
    
    [userDefaults synchronize];
}

+ (BOOL)getCashDrawerOpenActiveHigh {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.cashDrawerOpenActiveHigh;
}

+ (void)setCashDrawerOpenActiveHigh:(BOOL)activeHigh {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.cashDrawerOpenActiveHigh = activeHigh;
    
    [userDefaults setInteger:delegate.cashDrawerOpenActiveHigh forKey:@"cashDrawerOpenActiveHigh"];
    
    [userDefaults synchronize];
}

+ (NSInteger)getSelectedIndex {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return delegate.selectedIndex;
}

+ (void)setSelectedIndex:(NSInteger)index {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    delegate.selectedIndex = index;
}

@end
