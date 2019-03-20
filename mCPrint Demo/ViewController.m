//
//  ViewController.m
//  mpopGroceryDemo
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Communication.h"
#import "GlobalQueueManager.h"

typedef NS_ENUM(NSInteger, CellParamIndex) {
    CellParamIndexBarcodeData = 0,
    CellDetailParamIndexBarcodeData= 0
};

@interface ViewController ()

/* TABLEVIEW */
@property (nonatomic) NSMutableArray *cellArray;
@property (nonatomic) NSMutableArray *tablePriceArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/* UI ELEMENTS */
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

/* BUTTON PRESS ACTIONS */
- (IBAction)pushRefreshButton:(id)sender;
- (IBAction)pressPrintButton:(id)sender;
- (IBAction)pressCashDrawerButton:(id)sender;
- (IBAction)pressCannabisLabelButton:(id)sender;

/* STAR IO */
@property (nonatomic) StarIoExtManager *starIoExtManager;
@property SMPort *port;

/* STAR SCALE */
@property(nonatomic) NSMutableArray<STARScale *> *contents;
@property(nonatomic) STARScale *connectedScale;
@property (nonatomic) NSDictionary<NSNumber *, NSString *> *unitDict;

@property (nonatomic) NSString *currentWeight;
@property (nonatomic) NSString *price;
@property (nonatomic) NSString *checkoutPrice;
@property (nonatomic) NSMutableArray  *priceArray;
@property (nonatomic) NSString *priceForArray;

/* APP STATE */
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDictionaries];
    
    // delegate for textfield
    // _scaleTextField.delegate = self;
    // [_scaleTextField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];

    
    // Setup the tableview
    _tableView.delegate = self;
    _tableView.dataSource = self;
    

   
    // Some setup for our tableview and to keep track of prices
    _cellArray = [[NSMutableArray alloc] init];
    _priceArray = [[NSMutableArray alloc]init];
    _tablePriceArray = [[NSMutableArray alloc]init];
    
    // Instantiate our connection to the printer & barcode scanner
    _starIoExtManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeWithBarcodeReader
                                                      portName:[AppDelegate getPortName]
                                                  portSettings:[AppDelegate getPortSettings]
                                               ioTimeoutMillis:10000];                                   // 10000mS!!!
    
    // Set drawer polarity
    _starIoExtManager.cashDrawerOpenActiveHigh = [AppDelegate getCashDrawerOpenActiveHigh];
    
    // Setup the printer delegate methods
    _starIoExtManager.delegate = self;
    
    
    // An arrray for storing discovered BLE scales
    _contents = [NSMutableArray new];
    
}

- (void)viewDidAppear:(BOOL)animated {
    

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive)  name:UIApplicationDidBecomeActiveNotification  object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification  object:nil];
}

- (void)applicationDidBecomeActive {
    [_cellArray removeAllObjects];
    [_tablePriceArray removeAllObjects];
    [_starIoExtManager disconnect];
    [_priceArray removeAllObjects];
    
    NSString *title = @"";
    NSString *message = @"";
    
    if ([_starIoExtManager connect] == NO) {
        
        title = @"Printer Connection Error";
        message = @"Failed to connect to mC-Print. Please ensure the lightning cable is connected and try again.";
    }
    else {
        title = @"Printer Detected"; message = @"Printer is now connected.";
    }
    
    [_tableView reloadData];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // Handle OK button press action here
                                   // Currently do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applicationWillResignActive {
    [_starIoExtManager disconnect];
    
  
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Triggered when you push the refresh button
- (IBAction)pushRefreshButton:(id)sender {
    
    [_cellArray removeAllObjects];
    [_tablePriceArray removeAllObjects];
    [_priceArray removeAllObjects];
    _finalPriceLabel.text = 0;
    
    [_starIoExtManager disconnect];
    
    NSString *title = @"";
    NSString *message = @"";
    
    if ([_starIoExtManager connect] == NO) {
        title = @"Printer Connection Error";
        message = @"Failed to connect to mC-Print. Please ensure the lightning cable is connected and try again.";
    }
    else {
        title = @"Printer Detected"; message = @"mC-Print is now connected.";
    }
    
    [_tableView reloadData];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle your yes please button action here
                                   // Do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellArray.count;
    return _tablePriceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *cellParam = _cellArray[indexPath.row];
    
    
    static NSString *CellIdentifier = @"UITableViewCellStyleValue1";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if (cell != nil) {
        cell.textLabel.text = cellParam[CellParamIndexBarcodeData];
        cell.detailTextLabel.text = [self.tablePriceArray objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didBarcodeDataReceive:(StarIoExtManager *)manager data:(NSData *)data {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSMutableString *text = [NSMutableString stringWithString:@""];
    
    //NSLog(@"yoooooooo");
 
 
    const uint8_t *p = data.bytes;
    
    for (int i = 0; i < data.length; i++) {
        uint8_t ch = *(p + i);
        
        if(ch >= 0x20 && ch <= 0x7f) {
            [text appendFormat:@"%c", (char) ch];
            
            _checkoutPrice= [text substringWithRange:NSMakeRange(3, [text length]-3)];
     
            
            
        }
        else if (ch == 0x0d) {
            if (_cellArray.count > 30) {     // Max.30Line
                [_cellArray removeObjectAtIndex:0];
                [_tablePriceArray removeObjectAtIndex:0];
                [self.tableView reloadData];
                
            }
            if([text containsString:@"OG!"]) {
                text = (NSMutableString *)@"OG Kush";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
                
            }
            else if([text containsString:@"BD!"]) {
                text = (NSMutableString *)@"Blue Dream";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            else if([text containsString:@"PH!"]) {
                text = (NSMutableString *)@"Purple Haze";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
                
            }
            else if([text containsString:@"PX!"]) {
                text = (NSMutableString *)@"Pineapple Express";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            else if([text containsString:@"SD!"]) {
                text = (NSMutableString *)@"Sour Diesel";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            else if([text containsString:@"GC!"]) {
                text = (NSMutableString *)@"Green Crack";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            else if([text containsString:@"CK!"]) {
                text = (NSMutableString *)@"Cookies Kush";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            else if([text containsString:@"NL!"]) {
                text = (NSMutableString *)@"Northern Lights";
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            
            else {
                [_cellArray addObject:@[text]];
                [_tablePriceArray addObject:_checkoutPrice];
            }
            
        }
        
    }
    _priceForArray = [_checkoutPrice substringWithRange:NSMakeRange(1, [_checkoutPrice length]-1)];
    
    float priceTotal = [_priceForArray floatValue];
    
    [_priceArray addObject:[NSNumber numberWithFloat:priceTotal]];
    
    NSNumber * sum = [_priceArray valueForKeyPath:@"@sum.self"];
    
    _finalPriceLabel.text = [NSString stringWithFormat:@"%.02lf",[sum doubleValue]];
    
                             
    
    
    
    
    [_tableView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_cellArray.count - 1 inSection:0];

    
    [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
  
    
    /*
    ISDCBBuilder *displayBuilder = [StarIoExt createDisplayCommandBuilder:StarIoExtDisplayModelSCD222];
    [displayBuilder appendClearScreen];
    [displayBuilder appendData:(NSData *)[text dataUsingEncoding:NSASCIIStringEncoding]];
    
    [displayBuilder appendSpecifiedPosition:14 y:1];
    [displayBuilder appendData:(NSData *)[@"@ $10/g" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [displayBuilder appendSpecifiedPosition:0 y:2];
    [displayBuilder appendData:(NSData *)[_currentWeight dataUsingEncoding:NSASCIIStringEncoding]];
    
    [displayBuilder appendSpecifiedPosition:14 y:2];
    [displayBuilder appendData:(NSData *)[_price dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSData *commands = [displayBuilder.passThroughCommands copy];
    
    [_starIoExtManager.lock lock];
    
    [Communication sendCommands:commands port:_starIoExtManager.port completionHandler:^(BOOL result, NSString *title, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // do nothing, continue
            [_starIoExtManager.lock unlock];
        });
    }];
     
     */
}


     

- (void)initDictionaries {
    _unitDict = @{@(STARUnitInvalid): @"Invalid",
                  @(STARUnitMG): @"mg",
                  @(STARUnitG): @"g",
                  @(STARUnitCT): @"ct",
                  @(STARUnitMOM): @"mom",
                  @(STARUnitOZ): @"oz",
                  @(STARUnitLB): @"pound",
                  @(STARUnitOZT): @"ozt",
                  @(STARUnitDWT): @"dwt",
                  @(STARUnitGN): @"GN",
                  @(STARUnitTLH): @"tlH",
                  @(STARUnitTLS): @"tlS",
                  @(STARUnitTLT): @"tlT",
                  @(STARUnitTO): @"to",
                  @(STARUnitMSG): @"MSG",
                  @(STARUnitBAT): @"BAt",
                  @(STARUnitPCS): @"PCS",
                  @(STARUnitPercent): @"%",
                  @(STARUnitCoefficient): @"#"
                  };
}

- (void)didPrinterImpossible:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterOnline:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterOffline:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterPaperReady:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterPaperNearEmpty:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    /* The following printers do not have a low paper sensor:
     * TSP100, TSP100III, mC-Print, mPOP, portables
     */
}

- (void)didPrinterPaperEmpty:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterCoverOpen:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterCoverClose:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didCashDrawerOpen:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didCashDrawerClose:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderImpossible:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderConnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderDisconnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryConnectSuccess:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryConnectFailure:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryDisconnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didStatusUpdate:(StarIoExtManager *)manager status:(NSString *)status {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (IBAction)pressPrintButton:(id)sender {
    
   
    
    
    ISCBBuilder *receiptBuilder = [StarIoExt createCommandBuilder:StarIoExtEmulationStarPRNT];
    
    NSStringEncoding encoding = NSASCIIStringEncoding;
    [receiptBuilder appendCodePage:SCBCodePageTypeCP998];
    [receiptBuilder appendAlignment:SCBAlignmentPositionCenter];
    
    [receiptBuilder appendData:[@"Northern Lights\n"
                         "348 Green Ave\n"
                         "New York, NY 10001\n"
                         "\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionLeft];
    [receiptBuilder appendData:[@"------------------------------------------------\n"
                         "\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendDataWithEmphasis:[@"SALE\n" dataUsingEncoding:encoding]];
    [receiptBuilder appendData:[@"SKU               Description              Total\n"
                                "300678566         OG Kush                    10.99\n"
                                "300692003         Sour Diesel                13.99\n"
                                "300651148         Purple Haze                12.99\n"
                                "300642980         Green Crack                14.99\n"
                                "\n"
                                "------------------------------------------------\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionRight];
    [receiptBuilder appendData:[@"Subtotal:   $ 52.96\n"
                                "Tax:   $ 0.00\n" dataUsingEncoding:encoding]];
    
    [receiptBuilder appendData:[@"Total:   $ 52.96\n" dataUsingEncoding:encoding]];
    [receiptBuilder appendAlignment:SCBAlignmentPositionRight];
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionCenter];
    [receiptBuilder appendData:[@"Thank you for shopping at \nNorthern Lights!\n" dataUsingEncoding:encoding]];
    
    
    [receiptBuilder appendAlignment:SCBAlignmentPositionLeft];
    [receiptBuilder appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
    [receiptBuilder appendPeripheral:SCBPeripheralChannelNo1];
    [receiptBuilder appendPeripheral:SCBPeripheralChannelNo2];
    
    //NSData *commands = [receiptBuilder.commands copy];
    
    [_starIoExtManager.lock lock];
    
    dispatch_async(GlobalQueueManager.sharedManager.serialQueue, ^{
        [Communication sendCommands:[receiptBuilder.commands copy]
                               port:self->_starIoExtManager.port
                  completionHandler:^(BOOL result, NSString *title, NSString *message) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          UIAlertController * alert = [UIAlertController
                                                       alertControllerWithTitle:title
                                                       message:message
                                                       preferredStyle:UIAlertControllerStyleAlert];
                          
                          UIAlertAction* okButton = [UIAlertAction
                                                     actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         // Handle OK button press action here
                                                         // Currently do nothing
                                                     }];
                          
                          [alert addAction:okButton];
                          
                          if (result == NO) { [self presentViewController:alert animated:YES completion:nil]; }
                          [self->_starIoExtManager.lock unlock];
                          
                          //self.blind = NO;
            });
        }];
    });
    
    
    
    [_cellArray removeAllObjects];
    [_tablePriceArray removeAllObjects];
    [_priceArray removeAllObjects];
    _finalPriceLabel.text = 0;
    [_tableView reloadData];
    
}

- (IBAction)pressCashDrawerButton:(id)sender {
    ISCBBuilder *cashDrawerOne = [StarIoExt createCommandBuilder:StarIoExtEmulationStarPRNT];
    
    [cashDrawerOne appendPeripheral:SCBPeripheralChannelNo1];
    NSData *commands = [cashDrawerOne.commands copy];
    
    //[_starIoExtManager.lock lock];
    [Communication sendCommandsDoNotCheckCondition:commands port:_starIoExtManager.port completionHandler:^(BOOL result, NSString *title, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == NO) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alertView show];
            }
            //[_starIoExtManager.lock unlock];
        });
    }];
}


@end
