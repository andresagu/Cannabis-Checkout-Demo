//
//  ViewController.m
//  mpopGroceryDemo
//
//  Created by Andres Aguaiza on 3/29/19.
//  Copyright © 2019 Andres Aguaiza. All rights reserved.
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


//Pricing Tracker and Weight Tracking
@property(nonatomic) NSString *scaleW;

@property(nonatomic) double pricePerGram;
@property(nonatomic) double finalPrice;
@property(nonatomic) NSString* priceToPrint;
@property(nonatomic) NSString* barcodeDataOG;
@property(nonatomic) NSString* barcodeDataBlue;
@property(nonatomic) NSString* barcodeDataPurple;
@property(nonatomic) NSString* barcodeDataGS;
@property(nonatomic) NSString* barcodeDataSour;
@property(nonatomic) NSString* barcodeDataGreen;
@property(nonatomic) NSString* barcodeDataLights;
@property(nonatomic) NSString* barcodeDataCooks;

//Prices for the barcodes - will be calculated via the weight
@property(nonatomic) double OGprice;
@property(nonatomic) double BDprice;
@property(nonatomic) double PHprice;
@property(nonatomic) double GSprice;
@property(nonatomic) double SDprice;
@property(nonatomic) double GCprice;
@property(nonatomic) double NLprice;
@property(nonatomic) double CKprice;



@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDictionaries];
    
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

    
    
    
    // Setup the ScaleManager delegate methods
    STARScaleManager.sharedManager.delegate = self;
    
    // An arrray for storing discovered BLE scales
    _contents = [NSMutableArray new];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Start scanning for scales
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(),^{
        [STARScaleManager.sharedManager scanForScales];
    });
    
    if (_connectedScale != nil) {
        [STARScaleManager.sharedManager connectScale:_connectedScale];
    }

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
    
    
    //Adding scale connection check - adding connected scale to the manager
    if (_connectedScale != nil) {
        [STARScaleManager.sharedManager connectScale:_connectedScale];
    }
    
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
    
    //disconnect the scale manager & delegate methods when the application resigns
    if (_connectedScale != nil) {
        [STARScaleManager.sharedManager disconnectScale:_connectedScale];
    }
  
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


#pragma mark TABLE UI METHODS

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



#pragma mark Barcode Processing Methods
- (void)didBarcodeDataReceive:(StarIoExtManager *)manager data:(NSData *)data {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSMutableString *text = [NSMutableString stringWithString:@""];
 
 
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


#pragma mark Star EXT Manager delegate methods
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



#pragma mark Printer methods

//Creates a sample receipt - hardcoded and resets the table elements
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
        });
    }];
}

-(void)sendDataToDisplay{
    
    ISDCBBuilder *displayBuilder = [StarIoExt createDisplayCommandBuilder:StarIoExtDisplayModelSCD222];
    [displayBuilder appendClearScreen];
    [displayBuilder appendSpecifiedPosition:1 y:1];
    [displayBuilder appendData:(NSData *)[@"Weight: " dataUsingEncoding:NSASCIIStringEncoding]];
    [displayBuilder appendData:(NSData *)[_scaleW dataUsingEncoding:NSASCIIStringEncoding]];
    
    
    NSData *commands = [displayBuilder.passThroughCommands copy];
    
    [_starIoExtManager.lock lock];
    
    [Communication sendCommands:commands port:_starIoExtManager.port completionHandler:^(BOOL result, NSString *title, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // do nothing, continue
            [self->_starIoExtManager.lock unlock];
        });
    }];
    
    
    
}

#pragma mark Scale delegate methods that will update UI

- (void)scale:(STARScale *)scale didReadScaleData:(STARScaleData *)scaleData error:(NSError *)error {
    
    _currentWeight = [NSString stringWithFormat:@"%.03lf %@", scaleData.weight, _unitDict[@(scaleData.unit)]];
    _price = [NSString stringWithFormat:@"$%.02lf", scaleData.weight * 10];
    _scaleW = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight, _unitDict[@(scaleData.unit)]];
    
    _weightLabel.text = _scaleW;
    //Set all the scale weights
    
    
    [self setProductPrices:scaleData.weight];
    
    //_finalPrice  = scaleData.weight * OGpricePerGram;
    
    
    
    _priceToPrint = [NSString stringWithFormat:@"$%.02lf", _finalPrice];
    
    NSLog(@"%@", _scaleW);
    NSLog(@"%@", _scaleWeight);
    NSLog(@"%@", _priceToPrint);
    
    [self sendDataToDisplay];
    
    
}

- (void)scale:(STARScale *)scale didUpdateSetting:(STARScaleSetting)setting error:(NSError *)error {
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        [alert addAction:action];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}




#pragma mark - STARScaleManagerDelegate

- (void)manager:(STARScaleManager *)manager didDiscoverScale:(STARScale *)scale error:(NSError *)error {
    [_contents addObject:scale];
    
    [STARScaleManager.sharedManager stopScan];
    [STARScaleManager.sharedManager connectScale:scale];
}

- (void)manager:(STARScaleManager *)manager didConnectScale:(STARScale *)scale error:(NSError *)error {
    NSLog(@"Scale %@ is now connected", scale.name);
    
    _connectedScale = scale.self;
    _connectedScale.delegate = self;
}

- (void)manager:(STARScaleManager *)manager didDisconnectScale:(STARScale *)scale error:(NSError *)error {
    NSLog(@"Scale %@ has been disconnected", scale.name);
}


/*Method that will hold the brute force calculation of prices to print on the sample barcodes that can be scanned into the POS
didn't want to put this all in the scale weight method which is more or less where this calculation should happen*/
-(void)setProductPrices
                 :(double)currentScaleWeight {
    
    //Pricing constants for different strains
    const double OGpricePerGram = 7.79;
    const double BDpricePerGram = 9.39;
    const double PHpricePerGram = 8.10;
    const double GSpricePerGram = 8.14;
    const double SDpricePerGram = 7.80;
    const double GCpricePerGram = 6.59;
    const double CKpricePerGram = 8.21;
    const double NLpricePerGram = 7.11;
    
    _OGprice = OGpricePerGram * currentScaleWeight;
    _BDprice = BDpricePerGram * currentScaleWeight;
    _PHprice = PHpricePerGram * currentScaleWeight;
    _GSprice = GSpricePerGram * currentScaleWeight;
    _SDprice = SDpricePerGram * currentScaleWeight;
    _GCprice = GCpricePerGram * currentScaleWeight;
    _CKprice = CKpricePerGram * currentScaleWeight;
    _NLprice = NLpricePerGram * currentScaleWeight;
    
}

-(NSData *)createCanabisBarcodes{
    
    if(_priceToPrint != nil){

            _barcodeDataOG = [@"{BOG!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _OGprice]];
     
            _barcodeDataBlue = [@"{BBD!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _BDprice]];

            _barcodeDataPurple= [@"{BPH!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _PHprice]];

            _barcodeDataGS= [@"{BPX!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _GSprice]];
 
            _barcodeDataSour= [@"{BSD!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _SDprice]];

            _barcodeDataGreen= [@"{BGC!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _GCprice]];
        
            _barcodeDataLights= [@"{BNL!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _CKprice]];

            _barcodeDataCooks= [@"{BCK!" stringByAppendingString:[NSString stringWithFormat:@"$%.02lf", _NLprice]];
    }
    else{
        NSLog(@"please weigh something");
    }
    
    //builder
    ISCBBuilder *Ticket = [StarIoExt createCommandBuilder:StarIoExtEmulationStarPRNT];
    NSStringEncoding encoding = NSASCIIStringEncoding;
    
    [Ticket beginDocument];
    
    [Ticket appendMultipleWidth:2];
    [Ticket appendMultipleHeight:2];
    [Ticket appendAlignment:SCBAlignmentPositionCenter];
    [Ticket appendData:[@"Please scan this ticekt at checkout" dataUsingEncoding:encoding]];
    [Ticket appendMultipleWidth:4];
    [Ticket appendMultipleHeight:4];
    [Ticket appendAlignment:SCBAlignmentPositionCenter];
    [Ticket appendLineFeed:2];
    [Ticket appendDataWithEmphasis:[_scaleW dataUsingEncoding:encoding]];
    [Ticket appendLineFeed];
    [Ticket appendMultipleHeight:1];
    [Ticket appendMultipleWidth:1];
    [Ticket appendAlignment:SCBAlignmentPositionCenter];
    [Ticket appendBarcodeData:[_barcodeDataOG dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataBlue dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataPurple dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataGS dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataSour dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataGreen dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataLights dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    [Ticket appendLineFeed:2];
    [Ticket appendBarcodeData:[_barcodeDataCooks dataUsingEncoding:NSASCIIStringEncoding]
                    symbology:SCBBarcodeSymbologyCode128
                        width:SCBBarcodeWidthMode2
                       height:40
                          hri:YES];
    
    [Ticket appendLineFeed];
    [Ticket appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
    [Ticket endDocument];
    NSData *printJob = [Ticket.commands copy];
    
    
    return printJob;
}

- (IBAction)printBarcodeSamples:(id)sender {
    
    NSData *printJob = [self createCanabisBarcodes];
    
    [_starIoExtManager.lock lock];
    [Communication sendCommandsDoNotCheckCondition:printJob port:_starIoExtManager.port completionHandler:^(BOOL result, NSString *title, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == NO) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alertView show];
            }
            [self->_starIoExtManager.lock unlock];
        });
    }];
    
    
}


@end

