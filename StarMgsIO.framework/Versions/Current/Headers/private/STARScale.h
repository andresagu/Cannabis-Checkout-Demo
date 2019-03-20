//
//  STARScale.h
//  StarMgsIO
//

#import <Foundation/Foundation.h>

#import "STARScaleDelegate.h"

@import CoreBluetooth;

typedef NS_ENUM(NSUInteger, STARScaleSetting) {
    STARScaleSettingZeroPointAdjustment
};


@interface STARScale : NSObject<CBPeripheralDelegate>

@property(nonatomic) NSString * _Nullable name;

@property(nonatomic) NSString * _Nullable identifier;

@property(nonatomic) CBPeripheral *peripheral;  //TODO: move to private category.

@property(nonatomic) id<STARScaleDelegate> _Nullable delegate;

- (void)updateSetting:(STARScaleSetting)setting;

@end
