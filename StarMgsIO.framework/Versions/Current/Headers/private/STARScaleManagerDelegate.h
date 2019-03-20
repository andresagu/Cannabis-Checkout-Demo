//
//  STARScaleManagerDelegate.h
//  StarMgsIO
//

#pragma once

@class STARScale, STARScaleManager;

@protocol STARScaleManagerDelegate

- (void)manager:(STARScaleManager *)manager didDiscoverScale:(STARScale *)scale error:(NSError *)error;

- (void)manager:(STARScaleManager *)manager didConnectScale:(STARScale *)scale error:(NSError *)error;

- (void)manager:(STARScaleManager *)manager didDisconnectScale:(STARScale *)scale error:(NSError *)error;

@end
