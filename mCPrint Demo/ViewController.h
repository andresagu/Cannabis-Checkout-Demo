//
//  ViewController.h
//  mpopGroceryDemo
//
//  Created by Andres Aguaiza on 3/29/19.
//  Copyright © 2019 Andres Aguaiza. All rights reserved.
//


#import <UIKit/UIKit.h>

#import <StarIO_Extension/StarIoExtManager.h>

#import <StarMgsIO/StarMgsIO.h>

@interface ViewController : UIViewController <StarIoExtManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UITextFieldDelegate, STARScaleManagerDelegate, STARScaleDelegate>

@property (weak, nonatomic) IBOutlet UILabel *finalPriceLabel;
@property(nonatomic) STARScale *scale;

@property (weak, nonatomic) IBOutlet UILabel *weightLabel;


@end

