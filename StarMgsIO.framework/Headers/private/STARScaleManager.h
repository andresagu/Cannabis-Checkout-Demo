//
//  STARScaleManager.h
//  StarMgsIO
//

#import <Foundation/Foundation.h>

#import "STARScaleManagerDelegate.h"

@import CoreBluetooth;

@interface STARScaleManager : NSObject<CBCentralManagerDelegate>

@property(nonatomic) id<STARScaleManagerDelegate> delegate;

+ (STARScaleManager *)sharedManager;

+ (instancetype)alloc __attribute__((unavailable));
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));

- (void)scanForScales;

- (void)stopScan;

- (void)connectScale:(nonnull STARScale *)scale;

- (void)disconnectScale:(nonnull STARScale *)scale;

@end
