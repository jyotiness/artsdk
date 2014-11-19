//
//  PAAShippingAddressViewController.m
//  PhotosArt
//
//  Created by Jobin on 03/10/12.
//
//

#import "ACShipAddressViewController.h"
#import "ACPaymentViewController.h"
#import "ACAddressBookCustomCell.h"
#import "ACCheckoutTextField.h"
#import "ACPrinterReceiptViewController.h"
#import "ACWebViewController.h"
#import "ArtAPI.h"
#import "SVProgressHUD.h"
#import "UIColor+Additions.h"
#import "Analytics.h"
#import "ACKeyboardToolbarView.h"
#import "NSString+Additions.h"
#import "AccountManager.h"
#import <QuartzCore/QuartzCore.h>
//#import "PayPalPaymentViewController.h"

#define  COUNTRY_PICKER_TAG 5
#define  STATE_PICKER_TAG 8
#define  CHECKOUT_PICKER_HEIGHT 256

@interface ACShipAddressViewController () <ACKeyboardToolbarDelegate>
{
    BOOL mCountryPickerInvoked;
    UIButton *_nextButton;//, *payPalButton;
//    UIView * _headerView ;
    UILabel *_tableHeaderLabel;
}

@property(nonatomic, copy) NSString *email;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *confirmPassword;
@property(nonatomic, strong) NSString * error;
@property(nonatomic, strong) NSMutableDictionary * fieldErrors;

@end

@implementation ACShipAddressViewController 
@synthesize FooterNextViewButton,stateButton,statePickerValue;
@synthesize name = name_,lastName ;
@synthesize company = company_ ;
@synthesize shippingAddressTableView;
@synthesize phone = phone_ ;
@synthesize tagFromPicker,countryPickerValue;
@synthesize contactPickeMode,contactAdresses,willShowCityAndState;
@synthesize addressLine1,addressLine2,city,postalCode,countryButton;
@synthesize countries = _countries;
@synthesize countryNamesArray,countryIDArray;
@synthesize states = _states;
@synthesize dataShippingOptions = _dataShippingOptions;
@synthesize selectedShippingType = _selectedShippingType;
@synthesize selectedIndexPath;
@synthesize txtActiveField,zipLabelText;
@synthesize pickerHolderView = mPickerHolderView;
@synthesize firstNameTextField,lastNameTextField,address1TextField,address2TextField,companyTextField,zipTextField,cityTextField;
@synthesize failedTextField = mFailedTextField;
@synthesize stateTextField,emailTextField,emailAddress;
@synthesize stateValue,selectedCountryIndex,selectedStateIndex,selectedCountryCode;
@synthesize emailArray,cityArray,stateValidationRequired,phoneValidationRequired,phoneField,zipUnderValidation;
@synthesize topNavBarImageView=_topNavBarImageView;
@synthesize isModal = _isModal;
@synthesize isUSAddressInvalid;
@synthesize didTapNext;

bool isContinueButtonPressed = NO;
#define kOFFSET_FOR_KEYBOARD 80.0
int nameOrigin=0;



///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([self canPerformAction:@selector(setEdgesForExtendedLayout:) withSender:self]){
        [self setEdgesForExtendedLayout:(UIRectEdgeBottom|UIRectEdgeLeft|UIRectEdgeRight)];
    }
    
    // Listen for notification kACNotificationDismissModal
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissModal) name:kACNotificationDismissModal object:nil];
    
    self.title = [ACConstants getLocalizedStringForKey:@"&&_CHECKOUT" withDefaultValue:@"ART.COM CHECKOUT"];

	self.name = @"" ;
    self.lastName = @"";
	self.company = @"" ;
	self.phone = @"" ;
    self.addressLine1 = @"";
    self.addressLine2 = @"";
    self.city = @"";
    self.postalCode = @"";
    self.error = nil;
    self.email = @"";
    self.password = @"";
    self.confirmPassword = @"";
    
//    self.emailLoginTextField.layer.sublayerTransform = CATransform3DMakeTranslation(100, -40, -40);

    //NSLog(@"isDeviceConfigForUS: %d", [ArtAPI  isDeviceConfigForUS]);
    if([ArtAPI  isDeviceConfigForUS])
    {
        self.selectedCountryIndex = 0;
        self.countryPickerValue = @"United States";
    }
    else
    { 
        self.selectedCountryIndex = -1;
        self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY"  withDefaultValue:@"Select Country"];
    } 
    
    self.selectedStateIndex = -1;
    self.statePickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_STATE" withDefaultValue:@"Select State"];
    self.zipLabelText = [ACConstants getLocalizedStringForKey:@"ZIP_POSTAL_CODE" withDefaultValue:@"ZIP/Postal Code"];
    
    self.willShowCityAndState = NO;
    mCountryPickerInvoked = NO;

    // Create Header View
    
    // Create Info Button
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [infoButton setFrame:CGRectMake(4.0, 4.0f, 24.0f, 24.0f)];
    [infoButton setImage:[UIImage imageNamed:ARTImage(@"InfoButton23")] forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *infoBarButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    self.navigationItem.rightBarButtonItem = infoBarButton;
    
    // Set Table Header
//    self.shippingAddressTableView.tableHeaderView = _headerView;
    
    // Create Footer View
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    
    // Next / Continue Button
    _nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_nextButton setTitle:[ACConstants getLocalizedStringForKey:@"CONTINUE_CAPS" withDefaultValue:@"CONTINUE"] forState:UIControlStateNormal];
    [_nextButton setBackgroundColor:[ACConstants getPrimaryButtonColor]];
    [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _nextButton.titleLabel.font = [ACConstants getStandardBoldFontWithSize:32.0f];
    [_nextButton addTarget:self action:@selector(continueToPayment:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:_nextButton];
    
    CALayer *btnLayer = [_nextButton layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:2.0f];
    [_nextButton setContentEdgeInsets:UIEdgeInsetsMake(2, 0, 0, 0)];
    
	/*
    {// adding payPal Button
        payPalButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [payPalButton setTitle:@"PayPal" forState:UIControlStateNormal];
        [payPalButton setBackgroundColor:[ACConstants getPrimaryButtonColor]];
        [payPalButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        payPalButton.titleLabel.font = [ACConstants getStandardBoldFontWithSize:32.0f];
        [payPalButton addTarget:self action:@selector(payPalButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:payPalButton];
        
        CALayer *btnLayer = [payPalButton layer];
        [btnLayer setMasksToBounds:YES];
        [btnLayer setCornerRadius:2.0f];
        [payPalButton setContentEdgeInsets:UIEdgeInsetsMake(2, 0, 0, 0)];

    }
    */
    // Set Footer View
    self.shippingAddressTableView.tableFooterView = footerView;
    
    [self.shippingAddressTableView setBackgroundColor:[UIColor clearColor]];
    isDoingValidation = NO;
    
    self.screenName = @"Shipping Address Screen";
    
    // Load Countries and states.  If already cached in API, the use cache.
    // Or else fetch it from the server.
    if(  [ArtAPI getCountries] == nil ||  ((NSArray*)[ArtAPI getCountries]).count == 0) {
        //NSLog(@"No cached countries, fetch them from server");
        [self fetchCountryList];
    } else {
        //NSLog(@"Using cached countries");
        self.countries = [ArtAPI getCountries];
        self.states = [ArtAPI getStates];
        [self prepareCountryList];
    }
    self.tagFromPicker = COUNTRY_PICKER_TAG;
}

- (void)dismissModal {
    [[NSNotificationCenter defaultCenter] removeObserver:nil name:kACNotificationDismissModal object:nil];
}


-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
    
    UIButton *barBackButton = [ACConstants getBackButtonForTitle:[ACConstants getLocalizedStringForKey:@"BACK" withDefaultValue:@"Back"]];
    
    AppLocation currAppLoc = [ACConstants getCurrentAppLocation];
    if((![[AccountManager sharedInstance] isLoggedInForSwitchArt]) && AppLocationSwitchArt == currAppLoc)
    {
        self.shippingAddressTableView.tableHeaderView = self.loginHeaderView;
        self.loginTitleLabel.font = [ACConstants getStandardBoldFontWithSize:26.0f];
        self.loginView.hidden = NO;
        self.signupView.hidden = YES;
        _nextButton.enabled = NO;

/*        [self.loginFbButton setBackgroundColor:[ACConstants getPrimaryButtonColor]];
        [self.loginFbButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.loginFbButton.titleLabel.font = [ACConstants getStandardBoldFontWithSize:32.0f];
        
        [self.loginEmailButton setBackgroundColor:[UIColor grayColor]];
        [self.loginEmailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.loginEmailButton.titleLabel.font = [ACConstants getStandardBoldFontWithSize:32.0f]; */
    }
    
    
    // Allow the calling view controller to define the back button behavior
    if ([self.delegate respondsToSelector:@selector(didPressBackButton:)]){
        [barBackButton addTarget:self action:@selector(didPressBackButton:) forControlEvents:UIControlEventTouchUpInside];
    } else {
    
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
            [barBackButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        }else{
            [barBackButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
        }
        
    }
    
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithCustomView:barBackButton];
    
    self.navigationItem.leftBarButtonItem = backBarButton;
    
    self.navigationItem.hidesBackButton = YES;
    
    // Table Header
//    _headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 40);
//    _tableHeaderLabel.frame = CGRectMake(0, 10, self.view.bounds.size.width, 30);
    
    // Adjust Next / Continue button
    CGFloat buttonStartScreenWidth = 200;
    if(ACIsPad()){
        // Adjust the next button so that it fits on one screen on the iPad

        _nextButton.frame = CGRectMake(self.view.bounds.size.width/2 - buttonStartScreenWidth/2, 0, buttonStartScreenWidth, 44);
        //_nextButton.frame = CGRectMake((58.0), 0, buttonStartScreenWidth, 44);
        //payPalButton.frame = CGRectMake((_nextButton.frame.origin.x+_nextButton.frame.size.width) + 20.0 , 0, buttonStartScreenWidth, 44);
        
    } else {
        _nextButton.frame = CGRectMake(self.view.bounds.size.width/2 - buttonStartScreenWidth/2, 10, buttonStartScreenWidth, 54);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Configure Picker (Must be called in viewWillAppear)
    [self configureThePicker];
    
    // Preconnect to PayPal early
    //[PayPalMobile preconnectWithEnvironment:PayPalEnvironmentSandbox];

}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [ super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:nil name:kACNotificationDismissModal object:nil];
    [self setShippingAddressTableView:nil];
    [self setFooterNextViewButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            return NO;
            
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return YES;
    }
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return (self.needSignUp)?3:2;
}



-(void)configureThePicker
{
    //NSLog(@"configureThePicker: %f", self.view.frame.size.width );
    UIView *pickerHolderView = nil;
    
    pickerHolderView = [[ UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame)+80, self.view.frame.size.width, CHECKOUT_PICKER_HEIGHT)];
    
    if(!self.pickerHolderView)
    {
        self.pickerHolderView = pickerHolderView;
        pickerHolderView.backgroundColor = [UIColor whiteColor];
        self.countrypickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0,40, self.view.frame.size.width,CHECKOUT_PICKER_HEIGHT-40)];
        self.countrypickerView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.countrypickerView.delegate = self;
        self.countrypickerView.dataSource = self;
        self.countrypickerView.showsSelectionIndicator = YES;
        
        if([ACConstants isArtCircles]){
            [self.countrypickerView setBackgroundColor:[UIColor whiteColor]];
        }
        
        
        CGFloat screenWidth = CGRectGetWidth([self.view getCurrentScreenBoundsDependOnOrientation]);
        if((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ){
            screenWidth = self.view.bounds.size.width;
        }
        
        ACKeyboardToolbarView * toolbar = [[ACKeyboardToolbarView alloc] initWithFrame:CGRectMake(0, 0,screenWidth, 44)];
        toolbar.toolbarDelegate = self;
        toolbar.tag = 2;
        
        [pickerHolderView addSubview:toolbar];
        [pickerHolderView addSubview:self.countrypickerView];
        [self.view addSubview:pickerHolderView];
    }
}

-(void)countryPickerPressed:(id)sender
{
    //NSLog(@"countryPickerPressed");
    
    [self configureThePicker];
    
//    if([ self.txtActiveField isFirstResponder])
//        [ self.txtActiveField resignFirstResponder];
    [self.view endEditing:YES];
    
    self.tagFromPicker=[sender tag ];
    self.countrypickerView.delegate = self;
    self.countrypickerView.dataSource = self;
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:self.tagFromPicker inSection:0];
    [self keyboardWillShow:nil];
    
    if(COUNTRY_PICKER_TAG == self.tagFromPicker )
    {
        if(-1 == self.selectedCountryIndex)
        {
            self.selectedCountryIndex = 0;
        }
        
        //        mCountryPickerInvoked = YES;
        [ self.countrypickerView selectRow:self.selectedCountryIndex inComponent:0 animated:NO];
        [ self pickerView:self.countrypickerView didSelectRow:self.selectedCountryIndex inComponent:0];
    }
    else
    {
        if(-1 == self.selectedStateIndex)
            self.selectedStateIndex = 0;
        
        [ self.countrypickerView selectRow:self.selectedStateIndex inComponent:0 animated:NO];
        [ self pickerView:self.countrypickerView didSelectRow:self.selectedStateIndex inComponent:0];
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    
    //iPhone5 compatibility
    //CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height*[UIScreen mainScreen].scale;
    //NSLog(@"screenHeight: %f", screenHeight );
    
    self.pickerHolderView.frame = CGRectMake(0, self.view.frame.size.height - CHECKOUT_PICKER_HEIGHT, self.view.frame.size.width, CHECKOUT_PICKER_HEIGHT);
    //NSLog(@"self.pickerHolderView.frame: %@", NSStringFromCGRect(self.pickerHolderView.frame));
    
    [UIView commitAnimations];
}

-(void) scrollTextFieldToVisablePosition:(UITextField *)textField
{
    //NSLog(@"scrollTextFieldToVisablePosition");
    if (!textField)
    {
        return;
    }
}

-(void)hidePicker
{
    
    if(self.pickerHolderView.frame.origin.y == (self.view.frame.size.height - CHECKOUT_PICKER_HEIGHT))
    {
        [ self keyboardWillHide:nil];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        
        self.pickerHolderView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, CHECKOUT_PICKER_HEIGHT);
        
        [UIView commitAnimations];
        
    }
}

-(void)fetchCountryList {
    [ArtAPI
     requestForCartGetActiveCountryListWithSuccess:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
         //NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
         self.countries = [[JSON objectForKey:@"d"] objectForKeyNotNull:@"Countries"];
         
         if (self.countries&&![self.countries isKindOfClass:[NSNull class]]) {
             if(self.countries.count>0){
                 [ArtAPI setCountries:self.countries];
                 self.tagFromPicker = COUNTRY_PICKER_TAG;
                 [self configureThePicker];
                 [SVProgressHUD showWithStatus:[ACConstants getUpperCaseStringIfNeededForString:[ACConstants getLocalizedStringForKey:@"LOADING_STATES" withDefaultValue:@"LOADING STATES..."]] maskType:SVProgressHUDMaskTypeClear];
                 
                 [self prepareCountryList];
                 
                 NSString *countryCode = @"US";
                 
                 [ArtAPI
                  requestForCartGetActiveStateListByTwoDigitIsoCountryCode:countryCode success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                      //NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
                      self.states = [[JSON objectForKey:@"d"] objectForKeyNotNull:@"States"];
                      [self.shippingAddressTableView reloadData];
                      self.tagFromPicker = STATE_PICKER_TAG;
                      
                      [self configureThePicker];
                      [self pickerView:self.countrypickerView didSelectRow:self.selectedStateIndex inComponent:0];
                      
                      [SVProgressHUD dismiss];
                      [ArtAPI setStates:self.states];
                  }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
                      NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
                      [SVProgressHUD dismiss];
                  }];
             }else{
                 self.countries = nil;
                 [SVProgressHUD dismiss];
             }
         }else{
             self.countries = nil;
             [SVProgressHUD dismiss];
         }
     }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
         NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
         [SVProgressHUD dismiss];
     }];
    
}

-(void)prepareCountryList
{
    NSMutableArray *countryNameArray = [[NSMutableArray alloc] initWithCapacity:self.countries.count];
    NSMutableArray *countryIdArray = [[NSMutableArray alloc] initWithCapacity:self.countries.count];
    
    for (NSDictionary *dict in self.countries)
    {
        NSString *name = [dict objectForKeyNotNull:@"Name"];
        //if (![name isEqualToString:@"United States"])
        //{
            [countryNameArray addObject:name];
            [countryIdArray addObject:[dict objectForKeyNotNull:@"IsoA2"]];
        //}
    }

    self.countryNamesArray = countryNameArray;
    self.countryIDArray = countryIdArray;
    
    AppLocation currAppLoc = [ACConstants getCurrentAppLocation];
    
    if(AppLocationFrench == currAppLoc)
    {
        int countryCodeIndex = [countryIdArray indexOfObject:@"FR"];
        if(NSNotFound != countryCodeIndex)
        {
            self.selectedCountryCode = [self.countryIDArray objectAtIndex:countryCodeIndex];
            self.selectedCountryIndex = countryCodeIndex;
            self.countryPickerValue = [self.countryNamesArray objectAtIndex:countryCodeIndex];
            self.willShowCityAndState = YES;
            [self validateSelectedCountry:countryCodeIndex];
        }else{
            self.selectedCountryCode = nil;
            self.selectedCountryIndex = -1;
            self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY"  withDefaultValue:@"Select Country"];
        }
    }
    else if(AppLocationGerman == currAppLoc)
    {
        int countryCodeIndex = [countryIdArray indexOfObject:@"DE"];
        if(NSNotFound != countryCodeIndex)
        {
            self.selectedCountryCode = [self.countryIDArray objectAtIndex:countryCodeIndex];
            self.selectedCountryIndex = countryCodeIndex;
            self.countryPickerValue = [self.countryNamesArray objectAtIndex:countryCodeIndex];
            self.willShowCityAndState = YES;
            [self validateSelectedCountry:countryCodeIndex];
        }else{
            self.selectedCountryCode = nil;
            self.selectedCountryIndex = -1;
            self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY"  withDefaultValue:@"Select Country"];
        }
    }
    else
    {
        if([ArtAPI isDeviceConfigForUS])
        {
            int countryCodeIndex = [countryIdArray indexOfObject:@"US"];
            if(NSNotFound != countryCodeIndex)
            {
                self.selectedCountryCode = @"US";
                self.selectedCountryIndex = countryCodeIndex;
                self.countryPickerValue = [self.countryNamesArray objectAtIndex:countryCodeIndex];
                self.willShowCityAndState = NO;
                [self validateSelectedCountry:countryCodeIndex];
            }else{
                self.selectedCountryCode = nil;
                self.selectedCountryIndex = -1;
                self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY"  withDefaultValue:@"Select Country"];
            }
        }
        else
        {
            self.selectedCountryCode = nil;
            self.selectedCountryIndex = -1;
            self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY"  withDefaultValue:@"Select Country"];
        }
    }
}

- (void)infoButtonTapped:(UIButton *)sender
{
    [Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_INFO_BUTTON_PRESSED];
    
    [self showAbout];
    
    /* DISABLING HELPSHIFT
    NSString *aboutTitle = nil;
    AppLocation currAppLoc = [ACConstants getCurrentAppLocation];
    
    if(currAppLoc == AppLocationFrench){
        aboutTitle = NSLocalizedString(@"ABOUT_TITLE_MESPHOTOS", nil);
    }else if(currAppLoc == AppLocationGerman){
        aboutTitle = NSLocalizedString(@"ABOUT_TITLE_MYPHOTOS", nil);
    }else{
        aboutTitle = NSLocalizedString(@"ABOUT_TITLE_PHOTOSTOART", nil);
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:aboutTitle,NSLocalizedString(@"HELP", nil), nil];
    actionSheet.tag = 'n';
    [actionSheet showInView:self.view];
     
     */
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Notifications

-(void)keyboardWillShow:(NSNotification *)notiFication
{
    //NSLog(@"keyboardWillShow");
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        
        //NSLog(@"iPhone");
//        CGRect rect = self.shippingAddressTableView.frame;
//        
//        //iPhone5 compatibility
//        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height*[UIScreen mainScreen].scale;
//        if(screenHeight == 480){
//            //iphone no retina
//            rect.size.height = 416-225;
//        }else if(screenHeight == 960){
//            //iphone with retina
//            rect.size.height = 416-225;
//        }else{
//            //iphone5
//            rect.size.height = 504 - 225;
//        }
//        
//        self.shippingAddressTableView.frame = rect;
//        
//        //NSLog(@"Rect: %@ IndexPath to scroll to: %i,%i",NSStringFromCGRect(rect), self.selectedIndexPath.section, self.selectedIndexPath.row);
//        
//        // For some reason the phone and email fields are being scrolled after this is called, and there for making this scrollTo invalid.
//        // By delay it, the scrollTo works. This is not the ideal way to do it, but I can't figure why or where they are being scrolled.
//        double delayInSeconds = 0.1;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            [self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
//        });
        
        
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 270, 0.0);
        self.shippingAddressTableView.contentInset = contentInsets;
        self.shippingAddressTableView.scrollIndicatorInsets = contentInsets;
        [self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    }else{
        //NSLog(@"iPad");
        // Adjust table to fit keyboard       
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 245, 0.0);
        
        if(!self.didTapNext && (self.selectedIndexPath.section > 0)){
            contentInsets = UIEdgeInsetsMake(0, 0, 320, 0);
        }
        
        self.shippingAddressTableView.contentInset = contentInsets;
        self.shippingAddressTableView.scrollIndicatorInsets = contentInsets;
        [self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
        self.didTapNext = NO;
        
    }
}

-(void)keyboardWillHide:(NSNotification *)notiFication
{
    //NSLog(@"keyboardWillHide");
//    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
//        CGRect rect = self.shippingAddressTableView.frame;
//        
//        //iPhone5 compatibility
//        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height*[UIScreen mainScreen].scale;
//        if(screenHeight == 480){
//            //iphone no retina
//            rect.size.height = 416;
//        }else if(screenHeight == 960){
//            //iphone with retina
//            rect.size.height = 416;
//        }else{
//            //iphone5
//            rect.size.height = 504;
//        }
//        self.shippingAddressTableView.frame = rect;
//        
//        //NSLog(@"Rect at Hide: %@", NSStringFromCGRect(rect));
//        
//    } else {
        // Adjust table to fit keyboard
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        self.shippingAddressTableView.contentInset = contentInsets;
        self.shippingAddressTableView.scrollIndicatorInsets = contentInsets;
//    }
}



///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

//- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//}
//
//- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section)
    {
        case 0:
        {
            return self.willShowCityAndState?10:8;
            break;
        }
        case 1:{
            return 1;
            break;
        }
        case 2:{
            return 5;
            break;
        }
            
            
        default:{
            return 0;
            break;
        }
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (0 == section)
    {
        UIView *_headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
        _headerView.backgroundColor = [UIColor clearColor];
        
        // Create Header View Label
        _tableHeaderLabel = [[UILabel alloc] initWithFrame:_headerView.bounds];
        _tableHeaderLabel.text = [ACConstants getLocalizedStringForKey:@"SHIPPING_ADDRESS" withDefaultValue:@"SHIPPING ADDRESS"];
        _tableHeaderLabel.numberOfLines = 1;
        _tableHeaderLabel.textAlignment = NSTextAlignmentLeft;
        _tableHeaderLabel.textColor = [UIColor darkGrayColor];
        _tableHeaderLabel.textAlignment = NSTextAlignmentCenter;
        [_tableHeaderLabel setFont:[ACConstants getStandardBoldFontWithSize:26.0f]];
        [_tableHeaderLabel setTextColor:[UIColor artPhotosSectionTextColor]];
        _tableHeaderLabel.backgroundColor = [UIColor clearColor];
        [_headerView addSubview:_tableHeaderLabel];
        
        return _headerView;
    }
    else
    {
        UILabel *tableHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.view.bounds.size.width, 40)];
        tableHeaderLabel.text = (1 == section)?[ACConstants getLocalizedStringForKey:@"SEND_RECEIPT_TO" withDefaultValue:@"SEND RECEIPT TO"]:@"ACCOUNT INFO";
        tableHeaderLabel.numberOfLines = 1;
        tableHeaderLabel.textAlignment = NSTextAlignmentLeft;
        tableHeaderLabel.textColor = [UIColor darkGrayColor];
        tableHeaderLabel.textAlignment = NSTextAlignmentCenter;
        [tableHeaderLabel setFont:[ACConstants getStandardBoldFontWithSize:26.0f]];
        [tableHeaderLabel setTextColor:[UIColor artPhotosSectionTextColor]];
        tableHeaderLabel.backgroundColor = [UIColor clearColor];
        
        return tableHeaderLabel;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
//    if (section==1) {
        return  40.0;
//    }
//    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = nil;
    
    CGFloat height = 1 / [UIScreen mainScreen].scale;
    view = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 320., height)];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    return view;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section==1) {
        return 0;
    }else{
        return 1 / [UIScreen mainScreen].scale;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
}


// Customize the appearance of table view cells.

-(CGFloat) widthForTableView: (UITableView*) tableView {
    CGFloat groupedStyleMarginWidth;
    CGFloat tableViewWidth = tableView.frame.size.width;
    if([ACConstants isArtCircles]){
        groupedStyleMarginWidth = 0;
    }else{
        if (tableView.style == UITableViewStyleGrouped) {
            if (tableViewWidth > 20)
                groupedStyleMarginWidth = (tableViewWidth < 400) ? 10 : MAX(31, MIN(45, tableViewWidth*0.06));
            else
                groupedStyleMarginWidth = tableViewWidth - 10;
            
            if((tableViewWidth < 400)&&IS_IOS_7_ABOVE){
                groupedStyleMarginWidth = 0;
            }
            
        }
        else
            groupedStyleMarginWidth = 0.0;
    }
    
    return  tableView.frame.size.width - groupedStyleMarginWidth*2;
    
    //return groupedStyleMarginWidth;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"CheckoutTableIdentifier";
    ACAddressBookCustomCell * cell = (ACAddressBookCustomCell*)[tableView
                                                                dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    if (cell==nil)
    {
        cell = (ACAddressBookCustomCell *)[[ACBundle loadNibNamed:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ACAddressBookCustomCell-iPad" :@"ACAddressBookCustomCell"owner:self options:nil] objectAtIndex:0];
        
        [cell.pickerButton addTarget:self action:@selector(countryPickerPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contactPickerButton addTarget:self action:@selector(phoneBookContacts:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Make cell unselectable
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	int rownum=indexPath.row;
    cell.textField.delegate=self;
    cell.textField.hidden = NO;
    cell.textLabel.hidden = NO;
    cell.pickerButton.hidden = YES;
    cell.contactPickerButton.hidden=YES;
    // Adjust Textfield size
    CGRect textFieldFrame = cell.textField.frame;
    //NSLog(@"section: %d row: %d textFieldFrame: %@" ,indexPath.section, indexPath.row, NSStringFromCGRect(textFieldFrame));
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
        textFieldFrame.origin.x = 156;
    } else {
        textFieldFrame.origin.x = 115;
    }
    cell.textField.frame = textFieldFrame;
    //cell.textField.backgroundColor = [UIColor redColor];
    
    if(0 == indexPath.section)
    {
        cell.textField.tag = rownum;
        switch ( rownum )
        {
            case 0:
                self.firstNameTextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"FIRST_NAME" withDefaultValue:@"First Name"];
                cell.textField.text = self.name;
                cell.contactPickerButton.hidden=NO;
                cell.cellTitleButton.hidden = NO;
                cell.contactPickerButton.tag = indexPath.section;
                cell.textField.tag=indexPath.row;
                cell.textField.placeholder = @"";
                CGRect textFieldFrame = cell.textField.frame;
                if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
                    textFieldFrame.origin.x = 120;
                } else {
                    textFieldFrame.origin.x = 80;
                }
                cell.textField.frame = textFieldFrame;
                [cell.textField setClearButtonMode:UITextFieldViewModeNever];
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 1:
                self.lastNameTextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"LAST_NAME" withDefaultValue:@"Last Name"];
                cell.textField.text = self.lastName;
                cell.textField.tag = indexPath.row;
                cell.cellTitleButton.hidden = NO;
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 2:
                self.companyTextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"COMPANY" withDefaultValue:@"Company"];
                cell.textField.text=self.company;
                cell.cellTitleButton.hidden = NO;
                cell.textField.tag=indexPath.row;
                cell.textField.placeholder = [ACConstants getLocalizedStringForKey:@"OPTIONAL" withDefaultValue:@"Optional"];
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = [ UIColor blackColor];
                break ;
            case 3:
                self.address1TextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"ADDRESS" withDefaultValue:@"Address"] ;
                cell.textField.text = self.addressLine1;
                cell.textField.tag=indexPath.row;
                cell.cellTitleButton.hidden = NO;
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 4:
                self.address2TextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"ADDRESS_LINE_2" withDefaultValue:@"Address Line 2"];
                cell.textField.text=self.addressLine2;
                cell.textField.tag=indexPath.row;
                cell.textField.placeholder = [ACConstants getLocalizedStringForKey:@"OPTIONAL" withDefaultValue:@"Optional"];
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.cellTitleButton.hidden = NO;
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = [ UIColor blackColor];
                break ;
            case 5:
                cell.pickerButton.tag = indexPath.row;
                cell.textField.hidden = YES;
                cell.textLabel.hidden = YES;
                cell.cellTitleButton.hidden = YES;
                cell.pickerButton.hidden = NO;
                [cell.pickerButton setTitle:self.countryPickerValue forState:UIControlStateNormal];
                [cell.pickerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                cell.pickerButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                CGRect pickerButtonFrame = cell.pickerButton.frame;
                //pickerButtonFrame.size.width = [self widthForTableView:self.shippingAddressTableView];
                cell.pickerButton.frame = pickerButtonFrame;
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                self.countryButton = cell.pickerButton;
                self.countryButton.selected = isDoingValidation && (-1 == self.selectedCountryIndex);
                
                break ;
            case 6:
                self.zipTextField = cell.textField;
                cell.textField.text=self.postalCode;
                cell.textField.tag=indexPath.row;
                [cell.textField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                cell.cellTitleButton.hidden = NO;
                cell.textField.secureTextEntry = NO;

                cell.textLabel.text = self.zipLabelText;
                BOOL cityNotChoosenForUS = ([ self getCharacterCount:self.postalCode] > 0 && !self.willShowCityAndState);
                cell.textLabel.textColor = (((![cell.textField validateAsNotEmpty]) || ([ self.selectedCountryCode isEqualToString:@"US"] && self.isUSAddressInvalid) || cityNotChoosenForUS) && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 7:
                if(!self.willShowCityAndState)
                {
                    self.phoneField=cell.textField;
                    cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"PHONE" withDefaultValue:@"Phone"];
                    [cell.textField setKeyboardType:UIKeyboardTypeNumberPad];
                    cell.textField.text=self.phone;
                    cell.textField.tag=indexPath.row;
                    cell.textField.textAlignment = NSTextAlignmentRight;
                    cell.cellTitleButton.hidden = NO;
                    cell.textField.placeholder = self.phoneValidationRequired?@"":[ACConstants getLocalizedStringForKey:@"OPTIONAL" withDefaultValue:@"Optional"];
                    [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                    cell.textField.secureTextEntry = NO;

                    if([self.selectedCountryCode isEqualToString:@"DE"])
                    {
                        cell.textLabel.textColor = (self.phoneValidationRequired && ![cell.textField validateAsGermanPhoneNumber] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                    }
                    else
                    {
                        cell.textLabel.textColor = (self.phoneValidationRequired && ![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                    }
                }
                else
                {
                    self.cityTextField = cell.textField;
                    cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"CITY" withDefaultValue:@"City"];
                    cell.textField.text=self.city;
                    cell.textField.tag=indexPath.row;
                    cell.cellTitleButton.hidden = NO;
                    [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                    [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                    cell.textField.secureTextEntry = NO;

                    cell.textField.placeholder = @"";
                    
                    cell.textLabel.textColor = (((![cell.textField validateAsNotEmpty]) || ([ self.selectedCountryCode isEqualToString:@"US"] && self.isUSAddressInvalid)) && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                }
                
                break ;
            case 8:
                if([ self.selectedCountryCode isEqualToString:@"US"])
                {
                    cell.pickerButton.tag = indexPath.row;
                    cell.pickerButton.hidden = NO;
                    cell.textField.hidden = YES;
                    cell.textLabel.hidden = YES;
                    cell.cellTitleButton.hidden = YES;
                    [cell.pickerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    cell.pickerButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    CGRect pickerButtonFrame = cell.pickerButton.frame;
                    //pickerButtonFrame.size.width = [self widthForTableView:self.shippingAddressTableView];
                    cell.pickerButton.frame = pickerButtonFrame;
                    cell.textField.secureTextEntry = NO;

                    self.stateButton = cell.pickerButton;
                    self.stateButton.selected = isDoingValidation && ((-1 == self.selectedStateIndex) || ([ self.selectedCountryCode isEqualToString:@"US"] && self.isUSAddressInvalid));
                    
                    [self.stateButton setTitle:self.statePickerValue forState:UIControlStateNormal];
                }
                else
                {
                    self.stateTextField = cell.textField;
                    cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"STATE" withDefaultValue:@"State"];
                    cell.textField.text = self.stateValue;
                    cell.textField.tag=indexPath.row;
                    cell.cellTitleButton.hidden = NO;
                    [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                    cell.textField.placeholder = @"";
                    cell.textField.placeholder = self.stateValidationRequired?@"":[ACConstants getLocalizedStringForKey:@"OPTIONAL" withDefaultValue:@"Optional"];
                    [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                    cell.textField.secureTextEntry = NO;

                    cell.textLabel.textColor = (self.stateValidationRequired && ((![cell.textField validateAsNotEmpty]) || ([ self.selectedCountryCode isEqualToString:@"US"] && self.isUSAddressInvalid)) && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                }
                break;
            case 9:
                self.phoneField=cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"PHONE" withDefaultValue:@"Phone"];
                [cell.textField setKeyboardType:UIKeyboardTypeNumberPad];
                cell.textField.text=self.phone;
                cell.textField.tag=indexPath.row;
                cell.cellTitleButton.hidden = NO;
                cell.textField.textAlignment = NSTextAlignmentRight;
                cell.textField.placeholder = self.phoneValidationRequired?@"":[ACConstants getLocalizedStringForKey:@"OPTIONAL" withDefaultValue:@"Optional"];
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.secureTextEntry = NO;

                if([self.selectedCountryCode isEqualToString:@"DE"])
                {
                    cell.textLabel.textColor = (self.phoneValidationRequired && ![cell.textField validateAsGermanPhoneNumber] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                }
                else
                {
                    cell.textLabel.textColor = (self.phoneValidationRequired && ![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                }
                break;
        }
    }
    else if(1 == indexPath.section)
    {
        //cell.backgroundColor = [UIColor redColor];
        //cell.textField.tag = numberOfRowsInSection1 + indexPath.section;
        self.emailTextField=cell.textField;
        cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"EMAIL" withDefaultValue:@"Email"];
        cell.textField.text = self.emailAddress;
        cell.contactPickerButton.hidden = NO;
        cell.cellTitleButton.hidden = NO;
        cell.contactPickerButton.tag = indexPath.section;
        [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
        cell.textField.tag = 10;
        cell.textField.textAlignment = NSTextAlignmentRight;
        cell.textField.placeholder = @"";
        [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
        cell.textField.secureTextEntry = NO;

        CGRect emailFrame = cell.textField.frame;
        //NSLog(@"emailFrame: %@" ,NSStringFromCGRect(emailFrame));
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
            emailFrame.origin.x = 120;
        } else {
            emailFrame.origin.x = 80;
        }
        cell.textField.frame = emailFrame;
        cell.textLabel.textColor = (![cell.textField validateAsEmail] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
        
        // Adjust picker button
        //CGRect contactPickerButtonFrame = cell.contactPickerButton.frame;
        //contactPickerButtonFrame.origin.x = [self widthForTableView:self.shippingAddressTableView] - contactPickerButtonFrame.size.width;
        //cell.contactPickerButton.frame = contactPickerButtonFrame;
    }
    else
    {
        switch ( rownum )
        {
            case 0:
                self.firstNameTextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"FIRST_NAME" withDefaultValue:@"First Name"];
                cell.textField.text = self.name;
                cell.contactPickerButton.hidden=NO;
                cell.cellTitleButton.hidden = NO;
                cell.contactPickerButton.tag = indexPath.section;
                cell.textField.tag=indexPath.row;
                cell.textField.placeholder = @"";
                CGRect textFieldFrame = cell.textField.frame;
                if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
                    textFieldFrame.origin.x = 120;
                } else {
                    textFieldFrame.origin.x = 80;
                }
                cell.textField.frame = textFieldFrame;
                [cell.textField setClearButtonMode:UITextFieldViewModeNever];
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 1:
                self.lastNameTextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"LAST_NAME" withDefaultValue:@"Last Name"];
                cell.textField.text = self.lastName;
                cell.contactPickerButton.tag = indexPath.section;
                cell.cellTitleButton.hidden = NO;
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 2:
                self.lastNameTextField = cell.textField;
                cell.textLabel.text = [ACConstants getLocalizedStringForKey:@"EMAIL" withDefaultValue:@"Email"];
                cell.textField.text = self.emailAddress;
                cell.contactPickerButton.tag = indexPath.section;
                cell.cellTitleButton.hidden = NO;
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 3:
                self.lastNameTextField = cell.textField;
                cell.textLabel.text = @"Password";//[ACConstants getLocalizedStringForKey:@"PASSWORD" withDefaultValue:@"Password"];
                cell.textField.text = self.password;
                cell.contactPickerButton.tag = indexPath.section;
                cell.cellTitleButton.hidden = NO;
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = YES;
                
                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
            case 4:
                self.lastNameTextField = cell.textField;
                cell.textLabel.text = @"Confirm Password";//[ACConstants getLocalizedStringForKey:@"CONFIRM_PASSWORD" withDefaultValue:@"Confirm Password"];
                cell.textField.text = self.password;
                cell.contactPickerButton.tag = indexPath.section;
                cell.cellTitleButton.hidden = NO;
                [cell.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
                cell.textField.placeholder = @"";
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.secureTextEntry = NO;

                cell.textLabel.textColor = (![cell.textField validateAsNotEmpty] && isDoingValidation)?[UIColor redColor]:[ UIColor blackColor];
                break ;
                
                default:
                break;
        }
    }
    
    cell.textField.keyboardAppearance = UIKeyboardAppearanceLight;
    return cell;
}

-(UITextField*) makeTextField: (NSString*)text
                  placeholder: (NSString*)placeholder
{
	UITextField *tf = [[UITextField alloc] init];
	tf.placeholder = placeholder ;
	tf.text = text ;
	tf.autocorrectionType = UITextAutocorrectionTypeNo ;
	tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
	tf.adjustsFontSizeToFitWidth = YES;
	tf.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
	return tf ;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    if(textField == self.zipTextField)
    {
        if ([self.selectedCountryCode isEqualToString:@"US"])
        {
            NSString *newStr = [textField.text stringByAppendingValidString:string];
            if([@"" isEqualToString:string]){
                if([newStr length] > 0){
                    newStr = [newStr substringToIndex:[newStr length] - 1];
                }
            }
            if(5 == newStr.length)
            {
                self.zipUnderValidation = newStr;
                self.zipTextField.text = newStr;
//                [textField resignFirstResponder];
                [self.view endEditing:YES];
                
                [ self cityAndStateSuggestionForZip:newStr];
            }
        }
        
    }
    
    return YES;
}


-(void)cityAndStateSuggestionForZip:(NSString*)newStr
{
    [SVProgressHUD showWithStatus:[ACConstants getUpperCaseStringIfNeededForString:[ACConstants getLocalizedStringForKey:@"FETCHING_DETAILS" withDefaultValue:@"FETCHING DETAILS"]] maskType:SVProgressHUDMaskTypeClear];
    
    [ArtAPI
     cartGetCityStateSuggestionsCountryCode:@"US" zipCode:newStr success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
         //NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
         [self cartCityStateSuggestionDidFinishLoading: JSON];
     }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
         NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
         [SVProgressHUD dismiss];
         self.willShowCityAndState = YES;
         [self.shippingAddressTableView reloadData];
     }];
}

-(void) cartCityStateSuggestionDidFinishLoading:(id)JSON
{
    [SVProgressHUD dismiss];
    
    NSArray *addresses = [[JSON objectForKey:@"d"] objectForKeyNotNull:@"Addresses"];
    
    if(!addresses){
        self.willShowCityAndState = YES;
        [self.shippingAddressTableView reloadData];
        return;
    }
    
    if(1 <= addresses.count)
    {
        NSMutableArray *array = [ NSMutableArray array];
        for(NSDictionary *addrDict in addresses)
        {
            NSString *cityName = [ addrDict objectForKeyNotNull: @"City"];
            if(![array containsObject:cityName])
                [array addObject:cityName];
        }
        
        if(1< array.count)
        {
            NSString *title = [ACConstants getLocalizedStringForKey:@"CHOOSE_YOUR_CITY" withDefaultValue:@"Choose your City"];

            int currentDeviceOSVersion = [UIDevice currentDevice].systemVersion.intValue;
            if(currentDeviceOSVersion < 8)// For iOS 7 versions
            {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                         delegate:self
                                                                cancelButtonTitle:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?nil:[ACConstants getLocalizedStringForKey:@"CANCEL" withDefaultValue:@"Cancel"]
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:nil, nil];
                
                for(NSString *cName in array)
                {
                    [actionSheet addButtonWithTitle:cName];
                }
                
                self.cityArray = addresses;
                actionSheet.tag = 777;
                [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
            }
            else // For iOS 8
            {
               UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:nil];
               
                for(NSString *cityName in array)
                {
                    [anAlert addButtonWithTitle:cityName];
                }
                
                self.cityArray = addresses;
                anAlert.tag = 777;
                
                [anAlert show];
            }
            
        }
        else
        {
            NSDictionary *cityDict = [ addresses objectAtIndex:0];
            
            NSString *stateCode = [cityDict objectForKeyNotNull:@"State"];
            NSDictionary *stateDict = [ self getStateForCode:stateCode];
            NSString *stateName = [stateDict objectForKeyNotNull:@"Name"];
            if(stateName)
            {
                self.selectedStateIndex = [ self.states indexOfObject:stateDict];
                self.statePickerValue = [stateDict objectForKeyNotNull:@"Name"];
                self.postalCode = [cityDict objectForKeyNotNull:@"ZipCode"];
                self.city = [cityDict objectForKeyNotNull: @"City" ];
                
                self.willShowCityAndState = YES;
                
                
                [ self.shippingAddressTableView reloadData];
            }
        }
    }
    else if(0 == addresses.count)
    {
        self.selectedStateIndex = -1;
        self.statePickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_STATE" withDefaultValue:@"Select State"];
        self.city = @"";
        self.willShowCityAndState = YES;
        
        [ self.shippingAddressTableView reloadData];
    }
}

#pragma mark -- 
#pragma mark ALertView Delegate Method --
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex//CS: fixing added this for the iOS 8 issues fixes //CIRCLESIOS-1667
{
    if(111 == alertView.tag)
    {
        [ self chooseAdressForDict:[self.addressArray objectAtIndex:buttonIndex-1]];
    }
    else if(888 == alertView.tag)// Select Address Tag
    {
        if(0 == buttonIndex){
#ifndef __clang_analyzer__alertView            if (self.contactAdresses)
            {
                CFRelease(self.contactAdresses);
            }
#endif
            return;
        }
        
        [ self chooseAdressAtIndex:(int)buttonIndex-1];
    }
    else if(999 == alertView.tag)// Select Email Tag
    {
        if(0 == buttonIndex)
            return;
        
        NSString *email = [ self.emailArray objectAtIndex:buttonIndex-1];
        self.emailTextField.text = email;
        self.emailAddress = email;
        self.emailArray = nil;
        [self.shippingAddressTableView reloadData];
    }
    else if(777 == alertView.tag)// Select City Alert tag
    {
        if(0 == buttonIndex)
            return;
        
        NSDictionary *cityDict = [ self.cityArray objectAtIndex:buttonIndex-1];
        self.cityTextField.text = [cityDict objectForKeyNotNull:@"City"];
        
        NSString *stateCode = [cityDict objectForKeyNotNull:@"State"];
        NSDictionary *stateDict = [ self getStateForCode:stateCode];
        NSString *stateName = [stateDict objectForKeyNotNull:@"Name"];
        if(stateName)
        {
            self.selectedStateIndex = [ self.states indexOfObject:stateDict];
            self.statePickerValue = stateName;
            self.city = [cityDict objectForKeyNotNull:@"City"];
            self.postalCode = [cityDict objectForKeyNotNull:@"ZipCode"];
            
            self.willShowCityAndState = YES;
            [self hidePicker]; /*Diss miss country picker*/
            
            [ self.shippingAddressTableView reloadData];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextFieldDelegate



- (IBAction)textFieldFinished:(id)sender
{
//    [sender resignFirstResponder];
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [textField resignFirstResponder];
    [self.view endEditing:YES];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    //NSLog(@"textFieldDidBeginEditing: textField: %@", textField );
    
    self.txtActiveField = textField;
    
    [self hidePicker];
    
    //UITableViewCell *cell = (UITableViewCell *)[[[textField superview] superview] superview];

    NSInteger currentSelectedTextFieldTag = textField.tag;
    
    if(currentSelectedTextFieldTag == 10)//// CS: fixing CIRCLEIOS-1591
    {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    }
    else
    {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
    //NSLog(@"selectedIndexPath section: %d row: %d cell: %@", self.selectedIndexPath.section, self.selectedIndexPath.row, cell);s
    }

    if  (self.view.frame.origin.y >= 0)
    {
        //[self setViewMovedUp:YES];
    }
    if (textField==self.stateField)
    {
//        [stateField resignFirstResponder];
        [self.view endEditing:YES];
    }
    
    // Now add the view as an input accessory view to the selected textfield.
    //[textField setInputAccessoryView: [self createInputAccessoryView:YES isModal:NO]];
    ACKeyboardToolbarView * toolbar = [[ACKeyboardToolbarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([self.view getCurrentScreenBoundsDependOnOrientation]), 40)];
    toolbar.tag = 1;
    toolbar.toolbarDelegate = self;
    [textField setInputAccessoryView:toolbar];
    
}
// Textfield value changed, store the new value.
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (10 == textField.tag) {
        self.emailAddress = textField.text;
    }
    else if (7 == textField.tag) {
        self.city=textField .text;
    }
	else if ( 0 == textField.tag) {
		self.name = textField.text;
	}
    else if ( 1 == textField.tag) {
		self.lastName = textField.text;
	}
    else if ( 2 == textField.tag) {
		self.company = textField.text;
    }
    else if(3 == textField.tag)
    {
        self.addressLine1=textField.text;
    }
    else if (4 == textField.tag) {
        self.addressLine2=textField.text;
    }
    else if (6 == textField.tag) {
        self.postalCode=textField.text;
    }
    else if (8 == textField.tag)
    {
        self.stateValue = textField.text;
    }
    else if (9 == textField.tag) {
        self.phone = textField.text;
    }
    else if ((textField == self.emailLoginTextField) || (textField == self.emailSignupTextField)) {
        self.email = textField.text;
    }
    else if ((textField == self.passwordLoginTextField) || (textField == self.passwordSignupTextField)) {
        self.password=textField.text;
    }
    else if (textField == self.confirmPasswordTextField)
        self.confirmPassword=textField.text;

}


#pragma mark -  Action Methods
-(void)phoneBookContacts:(id)sender
{
    UIButton *contactBtn = (UIButton*)sender;
//    if([self.txtActiveField isFirstResponder])
    //        [ self.txtActiveField resignFirstResponder];
    [self.view endEditing:YES];
    
    self.contactPickeMode = (int)contactBtn.tag;
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    peoplePicker.navigationItem.title = (0 == contactBtn.tag)?[ACConstants getLocalizedStringForKey:@"CHOOSE_CONTACT" withDefaultValue:@"Choose Contact"]:[ACConstants getLocalizedStringForKey:@"CHOOSE_EMAIL" withDefaultValue:@"Choose Email"];
    //[self presentModalViewController:peoplePicker animated:YES];
    peoplePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:peoplePicker animated:YES completion:nil];
}

-(IBAction)goBack:(id)sender
{
    [ArtAPI setCountries:nil];
    [ArtAPI setStates:nil];

    [ self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) didPressBackButton:(id)sender {
    [self.delegate didPressBackButton:self];
}

/*
-(void)payPalButtonTapped:(UIButton *)payPalButton
{
    // Set up payPalConfig
    PayPalConfiguration *payPalConfig = [[PayPalConfiguration alloc] init];
    payPalConfig.acceptCreditCards = YES;
    payPalConfig.languageOrLocale = @"en";
    payPalConfig.merchantName = @"Art";
    payPalConfig.merchantPrivacyPolicyURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/privacy-full"];
    payPalConfig.merchantUserAgreementURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/useragreement-full"];

    
    PayPalItem *item1 = [PayPalItem itemWithName:@"Old jeans with holes"
                                    withQuantity:2
                                       withPrice:[NSDecimalNumber decimalNumberWithString:@"84.99"]
                                    withCurrency:@"USD"
                                         withSku:@"Hip-00037"];
    PayPalItem *item2 = [PayPalItem itemWithName:@"Free rainbow patch"
                                    withQuantity:1
                                       withPrice:[NSDecimalNumber decimalNumberWithString:@"0.00"]
                                    withCurrency:@"USD"
                                         withSku:@"Hip-00066"];
    PayPalItem *item3 = [PayPalItem itemWithName:@"Long-sleeve plaid shirt (mustache not included)"
                                    withQuantity:1
                                       withPrice:[NSDecimalNumber decimalNumberWithString:@"37.99"]
                                    withCurrency:@"USD"
                                         withSku:@"Hip-00291"];
    NSArray *items = @[item1, item2, item3];
    NSDecimalNumber *subtotal = [PayPalItem totalPriceForItems:items];
    
    // Optional: include payment details
    NSDecimalNumber *shipping = [[NSDecimalNumber alloc] initWithString:@"5.99"];
    NSDecimalNumber *tax = [[NSDecimalNumber alloc] initWithString:@"2.50"];
    PayPalPaymentDetails *paymentDetails = [PayPalPaymentDetails paymentDetailsWithSubtotal:subtotal
                                                                               withShipping:shipping
                                                                                    withTax:tax];
    
    NSDecimalNumber *total = [[subtotal decimalNumberByAdding:shipping] decimalNumberByAdding:tax];

    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = total;
    payment.currencyCode = @"USD";
    payment.shortDescription = @"Art Circles";
    payment.items = items;  // if not including multiple items, then leave payment.items as nil
    payment.paymentDetails = paymentDetails; // if not including payment details, then leave payment.paymentDetails as nil
    
    if (!payment.processable) {
        // This particular payment will always be processable. If, for
        // example, the amount was negative or the shortDescription was
        // empty, this payment wouldn't be processable, and you'd want
        // to handle that here.
    }

    // Update payPalConfig re accepting credit cards.

    PayPalPaymentViewController *paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment
                                                                                                configuration:payPalConfig
                                                                                                     delegate:self];
    [self presentViewController:paymentViewController animated:YES completion:nil];
    //[self pushViewController:paymentViewController animated:YES];

}

#pragma mark PayPalPaymentDelegate methods

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    NSLog(@"PayPal Payment Success!");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    NSLog(@"PayPal Payment Canceled");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

*/
    
-(void)continueToPayment:(id)sender
{
    [self.shippingAddressTableView reloadData]; /* Colors the Text label to black*/
    
    [Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_SHIPPING_ADDRESS_CONTINUE];
    
//    if([self.txtActiveField isFirstResponder])
//    {
//        [ self.txtActiveField resignFirstResponder];
//    }
    [self.view endEditing:YES];
    [self hidePicker];
    
    if ([self validateForm]&&!isContinueButtonPressed)
    {
        
        self.isUSAddressInvalid = NO;
        
        isContinueButtonPressed = YES;

        NSString *stateValueToBePassedToCall=nil;
        if ([self.selectedCountryCode isEqualToString:@"US"])
        {
            NSString *stateCode = @"CO";
            for (NSDictionary *state in self.states)
            {
                NSString *stateName=self.statePickerValue;
                
                //        NSUInteger indxOfState = [[state objectForKeyNotNull:@"Name"] indexOfObject: stateName];
                
                if ([[[state objectForKeyNotNull:@"Name"] uppercaseString] isEqualToString:[stateName uppercaseString]])
                {
                    stateCode = [state objectForKeyNotNull:@"StateCode"];
                    break;
                }
            }
            stateValueToBePassedToCall=stateCode;
        }
        else
        {
            stateValueToBePassedToCall=stateTextField.text;
        }
        
        [SVProgressHUD showWithStatus:[ACConstants getUpperCaseStringIfNeededForString:[ACConstants getLocalizedStringForKey:@"UPDATING_SHIPPING_ADDRESS" withDefaultValue:@"UPDATING SHIPPING ADDRESS"]] maskType:SVProgressHUDMaskTypeClear];
        
        
        [ArtAPI
         cartUpdateShippingAddressFirstName:self.name
         lastName:self.lastName
         addressLine1:self.addressLine1
         addressLine2:self.addressLine2
         companyName:self.company
         city:self.city
         state:(stateValueToBePassedToCall.length>0)?stateValueToBePassedToCall:@""
         twoDigitIsoCountryCode:self.selectedCountryCode
         zip:self.postalCode
         primaryPhone:(self.phone.length > 0)?self.phone:@""
         secondaryPhone:@""
         emailAddress:self.emailAddress success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             //NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
             [self cartUpdateShippingDidFinishLoading: JSON];
         }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
             NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
             
             NSString *errorMessagee = [JSON objectForKey:@"APIErrorMessage"];
             
             if([errorMessagee rangeOfString:@"combination"].location != NSNotFound){
                 self.isUSAddressInvalid = YES;
             }
             
             
             [SVProgressHUD dismiss];
             isContinueButtonPressed = NO;

             NSMutableDictionary *analyticsParams = [[NSMutableDictionary alloc] initWithCapacity:3];
             [analyticsParams setValue:[NSString stringWithFormat:@"%d",error.code] forKey:ANALYTICS_APIERRORCODE];
             [analyticsParams setValue:error.localizedDescription forKey:ANALYTICS_APIERRORMESSAGE];
             [analyticsParams setValue:[request.URL absoluteString] forKey:ANALYTICS_APIURL];
             [Analytics logGAEvent:ANALYTICS_CATEGORY_ERROR_EVENT withAction:errorMessagee withParams:analyticsParams];
             
             // Display error message here: APIErrorMessage
             UIAlertView *alert = [[ UIAlertView alloc] initWithTitle:[ACConstants getLocalizedStringForKey:@"ERROR" withDefaultValue:@"Error"]
                                                              message: [JSON objectForKey:@"APIErrorMessage"]
                                                             delegate:nil
                                                    cancelButtonTitle:[ACConstants getLocalizedStringForKey:@"OK" withDefaultValue:@"OK"]
                                                    otherButtonTitles:nil, nil];
             
             [ alert show];
             alert = nil;
             [self.shippingAddressTableView reloadData];
         }];
    }
    
}


-(void) cartUpdateShippingDidFinishLoading:(id)JSON
{
    NSDictionary *cart = [[JSON objectForKey:@"d"] objectForKeyNotNull:@"Cart"];
    
    if ([cart objectForKeyNotNull:@"CartId"] != nil) { //Don't override our local cart if the aoi fails here
        [ArtAPI setCart:cart];
        [ArtAPI setShippingCountryCode:self.selectedCountryCode];
    }
    isContinueButtonPressed = NO;
    [self loadDataFromAPI];
}

- (void) loadDataFromAPI {
    //NSLog(@"loadDataFromAPI");
    // Fetch a list of Countries
    [ArtAPI
     cartGetShippingOptionsWithSuccess:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
         //NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
         [self cartGetShippingOptionsRequestDidFinish: JSON];
     }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
         NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
         [SVProgressHUD dismiss];
     }];
}


-(void) cartGetShippingOptionsRequestDidFinish:(id)JSON
{
    [SVProgressHUD dismiss];
    NSDictionary *response = [JSON objectForKey:@"d"];
    
    // Pull out the shipping options:
    NSArray *shippingOptions = [response objectForKeyNotNull:@"ShippingOptions"];
    self.dataShippingOptions = shippingOptions;
    [ArtAPI setShippingCountryCode:self.selectedCountryCode];

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    
    NSString *currentYear = [NSString stringWithFormat:@"%d",[components year]];
    NSString *currentMonth = [NSString stringWithFormat:@"%d",[components month]];
    //NSLog(@"currentYear: %@ currentMonth: %@", currentYear,currentMonth );
    
    ArtAPI.currentYear = currentYear;
    ArtAPI.currentMonth = currentMonth;
    [self pushToPaymentScreen];
    
}

-(void)pushToPaymentScreen
{
    if(ACCheckoutTypePrintReciept == self.artCheckoutType)
    {
        ACPrinterReceiptViewController *chackOutController = [[ACPrinterReceiptViewController alloc] initWithNibName:@"ACPrinterReceiptViewController-iPad" bundle:ACBundle];
//        chackOutController.dataShippingOptions=self.dataShippingOptions;
        [ self.navigationController pushViewController:chackOutController animated:YES];
    }
    else
    {
        ACPaymentViewController *chackOutController = [[ACPaymentViewController alloc] initWithNibName:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
                                                       @"ACPaymentViewController-iPad" : @"ACPaymentViewController" bundle:ACBundle];
        chackOutController.dataShippingOptions=self.dataShippingOptions;
        [ self.navigationController pushViewController:chackOutController animated:YES];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ACKeyboardToolbarDelegate
- (void)keyboardToolbar: (ACKeyboardToolbarView*) keyboardToolbar didSelectNext: (id) next
{
    if(1 == self.selectedIndexPath.section)
    {
//        [self.emailTextField resignFirstResponder];
        [self.view endEditing:YES];
    }
    else
    {
        if ((self.selectedIndexPath.row) < 10)
        {
            if(self.willShowCityAndState)
            {
                self.selectedIndexPath = (10 == self.selectedIndexPath.row+1) ? [NSIndexPath indexPathForRow:0 inSection:1]:[NSIndexPath indexPathForRow:self.selectedIndexPath.row+1 inSection:0];
            }
            else{
                NSInteger incrementSelectedIndexPathRow = selectedIndexPath.row+1;
                self.selectedIndexPath = (8 == self.selectedIndexPath.row+1) ? [NSIndexPath indexPathForRow:0 inSection:1]:[NSIndexPath indexPathForRow:incrementSelectedIndexPathRow inSection:0];
            }
            
            self.didTapNext = YES;
            
            ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[self.shippingAddressTableView cellForRowAtIndexPath:self.selectedIndexPath];
            if (self.selectedIndexPath.row == COUNTRY_PICKER_TAG)
            {
                [ self countryPickerPressed:self.countryButton];
            }
            else if (self.selectedIndexPath.row == STATE_PICKER_TAG)
            {
                if ([self.selectedCountryCode isEqualToString:@"US"])
                    [ self countryPickerPressed:self.stateButton];
                else
                {
                    [cell.textField becomeFirstResponder];
                }
            }
            else
            {
                [cell.textField becomeFirstResponder];
            }
            
            [self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
    
    if(self.failedTextField)
    {
        ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[ self.shippingAddressTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.failedTextField.tag inSection:0]];
        cell.textLabel.textColor = [ UIColor blackColor];
        self.failedTextField = nil;
    }
}

- (void)keyboardToolbar: (ACKeyboardToolbarView*) keyboardToolbar didSelectPrevious: (id) previous {
    // If the active textfield is the first one, can't go to any previous
    // field so just return.
    
 /*   if(self.willShowCityAndState && (8 == self.selectedIndexPath.row))
    {
        
        if ([self.selectedCountryCode isEqualToString:@"US"])
        {
            [ self countryPickerPressed:self.stateButton];
        }
        else
        {
            self.selectedIndexPath = [NSIndexPath indexPathForRow:7 inSection:0];
            ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[self.shippingAddressTableView cellForRowAtIndexPath:self.selectedIndexPath];
            [cell.textField becomeFirstResponder];
        }
    }
    else*/ if(1 == self.selectedIndexPath.section)
    {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:self.willShowCityAndState?9:7 inSection:0];
        
//        [cell.textField becomeFirstResponder];
//        [self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
        [UIView animateWithDuration:0.40 animations:^{
            [self.shippingAddressTableView setContentOffset:CGPointMake(0, 360 - ([UIScreen mainScreen].bounds.size.height - 480)/2)];
        }completion:^(BOOL finished) {
            ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[self.shippingAddressTableView cellForRowAtIndexPath:self.selectedIndexPath];
            [cell.textField becomeFirstResponder];
        }];
        
    }
    else
    {
        if( 0 < self.selectedIndexPath.row)
        {
            if ((self.selectedIndexPath.row) <= 9)
            {
                NSInteger decrementSelectedIndexPathRow = selectedIndexPath.row-1;
                self.selectedIndexPath = [NSIndexPath indexPathForRow:decrementSelectedIndexPathRow inSection:0];
                
                ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[self.shippingAddressTableView cellForRowAtIndexPath:self.selectedIndexPath];
                //[self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                if (self.selectedIndexPath.row == COUNTRY_PICKER_TAG)
                {
                    [self countryPickerPressed:self.countryButton];
                }
                else if (self.selectedIndexPath.row == STATE_PICKER_TAG)
                {
                    if ([self.selectedCountryCode isEqualToString:@"US"])
                        [ self countryPickerPressed:self.stateButton];
                    else
                    {
                        [cell.textField becomeFirstResponder];
                    }
                }
                else
                {
                    [cell.textField becomeFirstResponder];
                }
                
                [self.shippingAddressTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            }
        }
        else
        {
//            ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[self.shippingAddressTableView cellForRowAtIndexPath:self.selectedIndexPath];
            //            [cell.textField resignFirstResponder];
            [self.view endEditing:YES];
        }
    }
    
    if(self.failedTextField)
    {
        ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[ self.shippingAddressTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.failedTextField.tag inSection:0]];
        cell.textLabel.textColor = [ UIColor blackColor];
        self.failedTextField = nil;
    }
}

- (void)keyboardToolbar: (ACKeyboardToolbarView*) keyboardToolbar didSelectDone: (id) done {
    //NSLog(@"didSelectDone tag: %d",  keyboardToolbar.tag);
    if( keyboardToolbar.tag == 1){
//        [self.txtActiveField resignFirstResponder];
        [self.view endEditing:YES];
        
        if(self.failedTextField)
        {
            ACAddressBookCustomCell *cell = (ACAddressBookCustomCell*)[ self.shippingAddressTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.failedTextField.tag inSection:0]];
            cell.textLabel.textColor = [ UIColor blackColor];
//            [ self.failedTextField resignFirstResponder];
            [self.view endEditing:YES];
            self.failedTextField = nil;
        }
    }
    if( keyboardToolbar.tag == 2){
        [self hidePicker];
        [ self.shippingAddressTableView reloadData];
    }
}



///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIPicker

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row == - 1)
    {
        return (self.tagFromPicker == STATE_PICKER_TAG)?self.statePickerValue:self.countryPickerValue;
    }
    
    if (self.tagFromPicker == STATE_PICKER_TAG)
    {
        NSMutableArray *c = [[NSMutableArray alloc] initWithCapacity:self.states.count];
        for (NSDictionary *dict in self.states)
        {
            [c addObject:[dict objectForKey:@"Name"]];
        }
        return [c objectAtIndex:row];
    }
    else if (self.tagFromPicker == COUNTRY_PICKER_TAG)
    {
        return [ self.countryNamesArray objectAtIndex:row];
    }
    return [ACConstants getLocalizedStringForKey:@"SELECT" withDefaultValue:@"Select"];
}


- (void)pickerView:(UIPickerView *)_pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (COUNTRY_PICKER_TAG == self.tagFromPicker) /* Country Picker */
    {
        self.selectedCountryCode = [self.countryIDArray objectAtIndex:row];
        self.selectedCountryIndex = row;
        self.countryPickerValue = [self pickerView:_pickerView titleForRow:row forComponent:component];
        [self validateSelectedCountry:row];
        
        if([ self.selectedCountryCode isEqualToString:@"US"])
        {
            if((5 == self.postalCode.length) && !mCountryPickerInvoked)
            {
                
                [ self cityAndStateSuggestionForZip:self.postalCode];
            }
            mCountryPickerInvoked = YES;
        }
        else
        {
            self.willShowCityAndState = (!self.willShowCityAndState)?![ self.selectedCountryCode isEqualToString:@"US"]:YES;
            mCountryPickerInvoked = NO;
        }
        
        
        [self.shippingAddressTableView reloadData];
    }
    else if (STATE_PICKER_TAG == self.tagFromPicker) /* State picker */
    {
        self.selectedStateIndex = row;
        self.statePickerValue = [self pickerView:_pickerView titleForRow:row forComponent:component];
    }
    [self.shippingAddressTableView reloadData];
}

-(void)validateSelectedCountry:(int)countryIndex
{
    self.stateValidationRequired = NO;
    self.phoneValidationRequired = NO;
    
    NSString *countryID = [ self.countryIDArray objectAtIndex:countryIndex];
    self.zipLabelText = [@"US" isEqualToString:countryID]?[ACConstants getLocalizedStringForKey:@"ZIP" withDefaultValue:@"ZIP"]:[ACConstants getLocalizedStringForKey:@"POSTAL_CODE" withDefaultValue:@"Postal Code"];
    
    if([@"US" isEqualToString:countryID] || [@"JP" isEqualToString:countryID])
    {
        self.stateValidationRequired = YES;
    }
    if([@"DE" isEqualToString:countryID] || [@"JP" isEqualToString:countryID] || [@"AT" isEqualToString:countryID] || [@"CH" isEqualToString:countryID])
    {
        self.phoneValidationRequired = YES;
    }
}

-(void)validateSelectedCountryName:(NSString*)countryName
{
    self.stateValidationRequired = NO;
    self.phoneValidationRequired = NO;
    
    for (NSString *name in self.countryNamesArray)
    {
        if ([name isEqualToString:self.countryPickerValue])
        {
            [self validateSelectedCountry:[ self.countryNamesArray indexOfObject:name]];
            [self.shippingAddressTableView reloadData];
            break;
        }
    }
}

-(BOOL) validateForm
{
    isDoingValidation = YES;
    self.failedTextField = nil;
    
    if (0 == [ self getCharacterCount:self.name])
    {
        self.failedTextField = self.firstNameTextField;
        [self.shippingAddressTableView scrollToRowAtIndexPath:[ NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
    else if (0 == [ self getCharacterCount:self.lastName])
    {
        self.failedTextField = self.lastNameTextField;
        [self.shippingAddressTableView scrollToRowAtIndexPath:[ NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
    else if (![self.emailTextField validateAsEmail])
        self.failedTextField = self.emailTextField;
    
    else if (0 == [ self getCharacterCount:self.addressLine1])
    {
        self.failedTextField = self.address1TextField;
        [self.shippingAddressTableView scrollToRowAtIndexPath:[ NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
    else if ((0 == [ self getCharacterCount:self.city]) && self.willShowCityAndState)
        self.failedTextField = self.cityTextField;
    else if (self.phoneValidationRequired &&  (0 == [ self getCharacterCount:self.phone]))
    {
        self.failedTextField = self.phoneField;
        [self.shippingAddressTableView scrollToRowAtIndexPath:[ NSIndexPath indexPathForRow:6 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
    
    else if (!self.countryPickerValue || [self.countryPickerValue isEqualToString:[ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY" withDefaultValue:@"Select Country"]])
    {
        [self.shippingAddressTableView scrollToRowAtIndexPath:[ NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
        return NO;
    }
    else if ([self.selectedCountryCode isEqualToString:@"US"])
    {
        if(!self.statePickerValue || [self.statePickerValue isEqualToString:[ACConstants getLocalizedStringForKey:@"SELECT_STATE" withDefaultValue:@"Select State"]])
        {
            [self.shippingAddressTableView scrollToRowAtIndexPath:[ NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
            return NO;
        }
        if(0 == [ self getCharacterCount:self.postalCode])
            self.failedTextField = self.zipTextField;
    }
    else if(![self.selectedCountryCode isEqualToString:@"US"])
    {
        if(0 == [ self getCharacterCount:self.postalCode])
            self.failedTextField = self.zipTextField;
        if(self.stateValidationRequired && (0 == [ self getCharacterCount:self.stateValue]))
            self.failedTextField = self.stateTextField;
    }
    
    if([self.selectedCountryCode isEqualToString:@"DE"])
    {
        NSString *phoneNumber = [self.phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
        phoneNumber = [ phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet symbolCharacterSet]];
        if(6 > [ self getCharacterCount:phoneNumber])
            self.failedTextField = self.phoneField;
    }
    
    if(self.failedTextField)
        [ self.shippingAddressTableView reloadData];
    
    return (self.failedTextField == nil)?YES:NO;
}

-(int)getCharacterCount:(NSString*)str
{
    return [ str stringByTrimmingCharactersInSet:[ NSCharacterSet whitespaceCharacterSet]].length;
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (STATE_PICKER_TAG == self.tagFromPicker)
    {
        NSMutableArray *c = [[NSMutableArray alloc] initWithCapacity:self.states.count];
        for (NSDictionary *dict in self.states)
        {
            [c addObject:[dict objectForKey:@"Name"]];
        }
        return [c count];
    }
    if (COUNTRY_PICKER_TAG == self.tagFromPicker)
    {
        
        NSMutableArray *c = [[NSMutableArray alloc] initWithCapacity:self.countries.count];
        //[c addObject:@"United States"];
        for (NSDictionary *dict in self.countries)
        {
            NSString *name = [dict objectForKeyNotNull:@"Name"];
            //if ([name isEqualToString:@"United States"] == NO)
           // {
                [c addObject:name];
           // }
        }
        return [c count];
    }
    return 0;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIActionSheetDelete

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // iPad does not have cancel button, increase index to think it does
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
        buttonIndex++;
    }
    
    if(111 == actionSheet.tag)
    {
        [ self chooseAdressForDict:[self.addressArray objectAtIndex:buttonIndex-1]];
    }
    else if(888 == actionSheet.tag)
    {
        if(0 == buttonIndex){
#ifndef __clang_analyzer__
            if (self.contactAdresses)
            {
                CFRelease(self.contactAdresses);
            }
#endif
            return;
        }

        [ self chooseAdressAtIndex:buttonIndex-1];
    }
    else if(999 == actionSheet.tag)
    {
        if(0 == buttonIndex)
            return;

        NSString *email = [ self.emailArray objectAtIndex:buttonIndex-1];
        self.emailTextField.text = email;
        self.emailAddress = email;
        self.emailArray = nil;
    }
    else if(777 == actionSheet.tag)
    {
        if(0 == buttonIndex)
            return;

        NSDictionary *cityDict = [ self.cityArray objectAtIndex:buttonIndex-1];
        self.cityTextField.text = [cityDict objectForKeyNotNull:@"City"];
        
        NSString *stateCode = [cityDict objectForKeyNotNull:@"State"];
        NSDictionary *stateDict = [ self getStateForCode:stateCode];
        NSString *stateName = [stateDict objectForKeyNotNull:@"Name"];
        if(stateName)
        {
            self.selectedStateIndex = [ self.states indexOfObject:stateDict];
            self.statePickerValue = stateName;
            self.city = [cityDict objectForKeyNotNull:@"City"];
            self.postalCode = [cityDict objectForKeyNotNull:@"ZipCode"];
            
            self.willShowCityAndState = YES;
            [self hidePicker]; /*Diss miss country picker*/
            
            [ self.shippingAddressTableView reloadData];
        }
    }
    else if ('n' == actionSheet.tag)
    {
        if(0 == buttonIndex)
        {
            //[Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_INFO_BUTTON_PRESSED];
            
            [self showAbout];
        }
        else if(1 == buttonIndex)
        {
            //[[Helpshift sharedInstance] showSupport:self];
        }

    }
}

-(void)showAbout{
    ACWebViewController * webViewController = [[ACWebViewController alloc] initWithURL:[NSURL URLWithString:[ArtAPI sharedInstance].aboutURL]];
    webViewController.toolbarHidden = YES;
    webViewController.titleHidden = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navigationController.navigationBarHidden = NO;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

-(NSDictionary*)getStateForCode:(NSString*)stateCode
{
    for(NSDictionary *state in self.states)
    {
        NSString *loopStateCode = [[[state objectForKeyNotNull:@"StateCode"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        if([stateCode isEqualToString:loopStateCode])
        {
            return state;
        }
    }
    
    return  nil;
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

// Called after the user has pressed cancel
// The delegate is responsible for dismissing the peoplePicker
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    //[peoplePicker dismissModalViewControllerAnimated:YES];
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}


- (void) populateEmailWithPerson:(ABRecordRef)person
{
    
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if(0 == ABMultiValueGetCount(emails))
    {
        NSString *fName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        NSString *contactName = lName?[NSString stringWithFormat:@"%@ %@",fName,lName]:[NSString stringWithFormat:@"%@",fName];
        
        //if(fName)
        //    CFRelease(fName);
        //if(lName)
        //    CFRelease(lName);
        NSString *noEmail = [ACConstants getLocalizedStringForKey:@"NO_EMAIL_ADDRESS_FOUND_FOR_CONTACT" withDefaultValue:@"No email address found for the contact"];
        UIAlertView *alert = [[ UIAlertView alloc] initWithTitle:[ACConstants getLocalizedStringForKey:@"EMAIL_NOT_FOUND" withDefaultValue:@"Email Not Found"]
                                                         message: [ NSString stringWithFormat:@"%@ \"%@\"",noEmail,contactName]
                                                        delegate:nil
                                               cancelButtonTitle:[ACConstants getLocalizedStringForKey:@"OK" withDefaultValue:@"OK"]
                                               otherButtonTitles:nil, nil];
        
        [ alert show];
        alert = nil;
    }
    else if(1 == ABMultiValueGetCount(emails))
    {
        //NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(emails, 0);
        NSString *email  = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, 0);
        self.emailTextField.text = email;
        self.emailAddress = email;
        [self.shippingAddressTableView reloadData];
    }
    else
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (CFIndex i = 0; i < ABMultiValueGetCount(emails); i++)
        {
            //NSString *label = (NSString *)ABMultiValueCopyLabelAtIndex(emails, i);
            NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, i);
            [ array addObject:email];
            
            //if (email) {
            //    CFRelease(email);
            //}
        }
        
        NSString *title = [ACConstants getLocalizedStringForKey:@"CHOOSE_AN_EMAIL" withDefaultValue:@"Choose an email"];
        
        int currentDeviceOSVersion = [UIDevice currentDevice].systemVersion.intValue;
        if(currentDeviceOSVersion < 8)// For iOS 7 versions
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                     delegate:self
                                                            cancelButtonTitle:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?nil:[ACConstants getLocalizedStringForKey:@"CANCEL" withDefaultValue:@"Cancel"]
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil, nil];
            
            for(NSString *emailStr in array)
            {
                [actionSheet addButtonWithTitle:emailStr];
            }
            
            self.emailArray = (NSArray*)array;
            actionSheet.tag = 999;
            [actionSheet showInView:[UIApplication sharedApplication].keyWindow];

        }
        else // For iOS 8
        {
            UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:nil];
            
            for(NSString *emailStr in array)
            {
                [anAlert addButtonWithTitle:emailStr];
            }
            
            self.emailArray = (NSArray*)array;
            anAlert.tag = 999;
            
            [anAlert show];
        }
    }
    if (emails){
        CFRelease(emails);
    }
}

-(void)chooseAdressForDict:(NSDictionary*)dict
{
    self.postalCode = [dict objectForKey:@"ZipCode"];
    self.city = [dict objectForKey:@"City"];
    
    NSString *countryFromAddress = [[dict objectForKey:@"Country"] uppercaseString];
    
    NSString *countryCodeFromAddress = [[[dict objectForKeyNotNull:@"CountryIsoA3"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
    
    if([[countryFromAddress uppercaseString] isEqualToString:@"USA"])
        countryFromAddress = @"US";
    
    if([[countryCodeFromAddress uppercaseString] isEqualToString:@"USA"])
        countryCodeFromAddress = @"US";
    
//    NSLog(@"%@",address);
    NSDictionary *phoneDict = [dict objectForKey:@"Phone"];
    if(phoneDict)
    {
        self.phone = [phoneDict objectForKeyNotNull:@"Primary"];
    }

    for(NSDictionary *country in self.countries)
    {
        NSString *loopCountryName = [[[country objectForKeyNotNull:@"Name"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        NSString *loopCountryCode = [[[country objectForKeyNotNull:@"IsoA2"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        if([countryFromAddress isEqualToString:loopCountryName]||[countryFromAddress isEqualToString:loopCountryCode]||[countryCodeFromAddress isEqualToString:loopCountryName]||[countryCodeFromAddress isEqualToString:loopCountryCode])
        {
            self.countryPickerValue = [country objectForKeyNotNull:@"Name"];
            self.selectedCountryIndex = [ self.countries indexOfObject:country];
            self.selectedCountryCode = [country objectForKeyNotNull:@"IsoA2"];
            break;
        }
    }
    
    if(self.selectedCountryIndex < 0){
        self.selectedCountryCode = nil;
    }
    
    if([self.selectedCountryCode isEqualToString:@"US"])
    {
        NSString *stateFromAddress = [[[dict objectForKey:@"State"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        for(NSDictionary *state in self.states)
        {
            NSString *loopStateCode = [[[state objectForKeyNotNull:@"StateCode"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
            if([stateFromAddress isEqualToString:loopStateCode])
            {
                self.selectedStateIndex = [ self.states indexOfObject:state];
                self.statePickerValue = [state objectForKeyNotNull:@"Name"];
                break;
            }
        }
    }
    else
    {
        self.stateTextField.text = [dict objectForKey:@"State"];
    }
    
    NSString *streetAddress = [dict objectForKey:@"Address1"];
    self.addressLine1 = [streetAddress stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    [ self.shippingAddressTableView reloadData];
    
#ifndef __clang_analyzer__
    if (self.contactAdresses)
    {
        CFRelease(self.contactAdresses);
    }
#endif
}

-(void)chooseAdressAtIndex:(int)index
{
    
    NSDictionary *address      = (__bridge_transfer NSDictionary *)ABMultiValueCopyValueAtIndex(self.contactAdresses, index);
    self.postalCode = [address objectForKey:@"ZIP"];
    self.city = [address objectForKey:@"City"];
    
    NSString *countryFromAddress = [[[address objectForKey:@"Country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
    
    NSString *countryCodeFromAddress = [[[address objectForKeyNotNull:@"CountryCode"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
    
    if([[countryFromAddress uppercaseString] isEqualToString:@"USA"])
        countryFromAddress = @"US";
    
    if([[countryCodeFromAddress uppercaseString] isEqualToString:@"USA"])
        countryCodeFromAddress = @"US";
    
    NSLog(@"%@",address);
    
    for(NSDictionary *country in self.countries)
    {
        NSString *loopCountryName = [[[country objectForKeyNotNull:@"Name"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        NSString *loopCountryCode = [[[country objectForKeyNotNull:@"IsoA2"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        if([countryFromAddress isEqualToString:loopCountryName]||[countryFromAddress isEqualToString:loopCountryCode]||[countryCodeFromAddress isEqualToString:loopCountryName]||[countryCodeFromAddress isEqualToString:loopCountryCode])
        {
            self.countryPickerValue = [country objectForKeyNotNull:@"Name"];
            self.selectedCountryIndex = [ self.countries indexOfObject:country];
            self.selectedCountryCode = [country objectForKeyNotNull:@"IsoA2"];
            break;
        }
    }
    
    if(self.selectedCountryIndex < 0){
        self.selectedCountryCode = nil;
    }
    
    if([self.selectedCountryCode isEqualToString:@"US"])
    {
        NSString *stateFromAddress = [[[address objectForKey:@"State"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        for(NSDictionary *state in self.states)
        {
            NSString *loopStateName = [[[state objectForKeyNotNull:@"Name"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
            NSString *loopStateCode = [[[state objectForKeyNotNull:@"StateCode"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
            if([stateFromAddress isEqualToString:loopStateName]||[stateFromAddress isEqualToString:loopStateCode])
            {
                self.selectedStateIndex = [ self.states indexOfObject:state];
                self.statePickerValue = [state objectForKeyNotNull:@"Name"];
                break;
            }
        }
    }
    else
    {
        self.stateTextField.text = [address objectForKey:@"State"];
    }
    
    NSString *streetAddress = [address objectForKey:@"Street"];
    self.addressLine1 = [streetAddress stringByReplacingOccurrencesOfString:@"\n" withString:@" "];

    [ self.shippingAddressTableView reloadData];
    
    #ifndef __clang_analyzer__
    if (self.contactAdresses)
    {
        CFRelease(self.contactAdresses);
    }
    #endif
}

- (void) populateDataWithLoginResponse:(NSDictionary*)dict
{
    NSDictionary *accountDetails = [dict objectForKeyNotNull:@"Account"];
    if(accountDetails)
    {
        NSDictionary *curatorInfo = [accountDetails objectForKeyNotNull:@"CuratorInfo"];
        if(curatorInfo)
        {
            NSString *firstName = [curatorInfo objectForKeyNotNull:@"FirstName"];
            NSString *lastNamePart = [curatorInfo objectForKeyNotNull:@"LastName"];
            self.name = [NSString stringWithFormat:@"%@",firstName];
            self.lastName = lastNamePart?[NSString stringWithFormat:@"%@",lastNamePart]:@"";
        }
        
        NSDictionary *profileInfo = [accountDetails objectForKeyNotNull:@"ProfileInfo"];
        if(profileInfo)
        {
            NSArray *addressesArray = [ profileInfo objectForKeyNotNull:@"Addresses"];
            if(addressesArray && addressesArray.count >0)
            {
                self.company = nil;
                self.postalCode = nil;
                self.city = nil;
                self.phone = nil;
                self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY" withDefaultValue:@"Select Country"];
                self.statePickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_STATE" withDefaultValue:@"Select State"];
                self.addressLine1 = nil;
                self.addressLine2 = nil;
                self.selectedStateIndex = -1;
                self.selectedCountryIndex = -1;
                self.willShowCityAndState = YES;
                self.addressArray = addressesArray;
                
                int count = (int)addressesArray.count;
                if(1 == count)
                {
                    [ self chooseAdressForDict:[addressesArray objectAtIndex:0]];
                }
                else if(1 < count)
                {
                    NSString *title = [ACConstants getLocalizedStringForKey:@"CHOOSE_AN_ADDRESS_FOR_SHIPMENT" withDefaultValue:@"Choose an Address for Shipment"];
                    
                    int currentDeviceOSVersion = [UIDevice currentDevice].systemVersion.intValue;
                    if(currentDeviceOSVersion < 8)// For iOS 7 versions
                    {
                        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                                 delegate:self
                                                                        cancelButtonTitle:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?nil:[ACConstants getLocalizedStringForKey:@"CANCEL" withDefaultValue:@"Cancel"]
                                                                   destructiveButtonTitle:nil
                                                                        otherButtonTitles:nil, nil];
                        
                        for(NSDictionary* dict in addressesArray)
                        {
                            /*CFStringRef labelStringRef = ABMultiValueCopyLabelAtIndex(self.contactAdresses, i);
                             //mkl localizing label
                             NSString *phoneLabelLocalized = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(labelStringRef);
                             NSString *labelName = [NSString stringWithFormat:@"%@",phoneLabelLocalized];
                             CFRelease(labelStringRef);
                             labelName = [ labelName stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                             labelName = [ labelName stringByReplacingOccurrencesOfString:@">!$_" withString:@""]; */
                            [actionSheet addButtonWithTitle:[dict objectForKeyNotNull:@"Street"]];
                        }
                        
                        actionSheet.tag = 111;
                        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
                        
                    }
                    else // For iOS 8
                    {
                        UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:nil];
                        
                        for(NSDictionary* dict in addressesArray)
                        {
                            /*CFStringRef labelStringRef = ABMultiValueCopyLabelAtIndex(self.contactAdresses, i);
                             //mkl localizing label
                             NSString *phoneLabelLocalized = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(labelStringRef);
                             NSString *labelName = [NSString stringWithFormat:@"%@",phoneLabelLocalized];
                             CFRelease(labelStringRef);
                             labelName = [ labelName stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                             labelName = [ labelName stringByReplacingOccurrencesOfString:@">!$_" withString:@""]; */
                            [anAlert addButtonWithTitle:[dict objectForKeyNotNull:@"Street"]];
                        }
                        anAlert.tag = 111;
                        
                        [anAlert show];
                    }
                    
                }
                
                [self.shippingAddressTableView reloadData];
                
                //Advance to the first required cell:
                if ([self.nameField.text length] < 1) {
                    [self.nameField becomeFirstResponder];
                    return;
                }
                if ([self.addressLine1Field.text length] < 1) {
                    [self.addressLine1Field becomeFirstResponder];
                    return;
                }
                if ([self.cityField.text length] < 1) {
                    [self.cityField becomeFirstResponder];
                    return;
                }
                
                if ([self.stateField.text length] < 1) {
                    [self.stateField becomeFirstResponder];
                    return;
                }
                if ([self.postalCodeField.text length] < 1) {
                    [self.postalCodeField becomeFirstResponder];
                    return;
                }
            }
        }
    }
}

- (void) populateDataForSignup:(ABRecordRef)person
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastNamePart = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    self.name = [NSString stringWithFormat:@"%@",firstName];
    self.lastName = lastNamePart?[NSString stringWithFormat:@"%@",lastNamePart]:@"";
    
    NSString *company = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    self.company = company;
    
    self.postalCode = nil;
    self.city = nil;
    self.phone = nil;
    self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY" withDefaultValue:@"Select Country"];
    self.statePickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_STATE" withDefaultValue:@"Select State"];
    self.addressLine1 = nil;
    self.addressLine2 = nil;
    self.selectedStateIndex = -1;
    self.selectedCountryIndex = -1;
    
    self.willShowCityAndState = YES;
    
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    int phoneCount = ABMultiValueGetCount(phones);
    if(1 <= phoneCount)
    {
        NSString *ph = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, 0);
        self.phone = ph;
    }
    if (phones) {
        CFRelease(phones);
    }
    
    ABMultiValueRef addresses = ABRecordCopyValue(person, kABPersonAddressProperty);
    self.contactAdresses = addresses;
    
#ifndef __clang_analyzer__
    int count = ABMultiValueGetCount(self.contactAdresses);
#endif
    if(1 == count)
    {
        [ self chooseAdressAtIndex:0];
    }
    else if(1 < count)
    {
        NSString *title = [ACConstants getLocalizedStringForKey:@"CHOOSE_AN_ADDRESS_FOR_SHIPMENT" withDefaultValue:@"Choose an Address for Shipment"];
        
        int currentDeviceOSVersion = [UIDevice currentDevice].systemVersion.intValue;
        if(currentDeviceOSVersion < 8)// For iOS 7 versions
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                     delegate:self
                                                            cancelButtonTitle:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?nil:[ACConstants getLocalizedStringForKey:@"CANCEL" withDefaultValue:@"Cancel"]
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil, nil];
            
            for (CFIndex i = 0; i < ABMultiValueGetCount(self.contactAdresses); i++)
            {
                CFStringRef labelStringRef = ABMultiValueCopyLabelAtIndex(self.contactAdresses, i);
                //mkl localizing label
                NSString *phoneLabelLocalized = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(labelStringRef);
                NSString *labelName = [NSString stringWithFormat:@"%@",phoneLabelLocalized];
                CFRelease(labelStringRef);
                labelName = [ labelName stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                labelName = [ labelName stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
                //NSLog(@"add button: %@", labelName);
                [actionSheet addButtonWithTitle:labelName];
            }
            actionSheet.tag = 888;
            [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
            
        }
        else // For iOS 8
        {
            UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:nil];
            
            for (CFIndex i = 0; i < ABMultiValueGetCount(self.contactAdresses); i++)
            {
                CFStringRef labelStringRef = ABMultiValueCopyLabelAtIndex(self.contactAdresses, i);
                
                NSString *phoneLabelLocalized = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(labelStringRef);
                NSString *labelName = [NSString stringWithFormat:@"%@",phoneLabelLocalized];
                CFRelease(labelStringRef);
                
                labelName = [ labelName stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                labelName = [ labelName stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
                
                [anAlert addButtonWithTitle:labelName];
            }
            
            anAlert.tag = 888;
            
            [anAlert show];
        }
        
    }
    
    [self.shippingAddressTableView reloadData];
    
    //Advance to the first required cell:
    if ([self.nameField.text length] < 1) {
        [self.nameField becomeFirstResponder];
        return;
    }
    if ([self.addressLine1Field.text length] < 1) {
        [self.addressLine1Field becomeFirstResponder];
        return;
    }
    if ([self.cityField.text length] < 1) {
        [self.cityField becomeFirstResponder];
        return;
    }
    
    if ([self.stateField.text length] < 1) {
        [self.stateField becomeFirstResponder];
        return;
    }
    if ([self.postalCodeField.text length] < 1) {
        [self.postalCodeField becomeFirstResponder];
        return;
    }
    
}


- (void) populateDataWithPerson:(ABRecordRef)person
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastNamePart = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    self.name = [NSString stringWithFormat:@"%@",firstName];
    self.lastName = lastNamePart?[NSString stringWithFormat:@"%@",lastNamePart]:@"";
    
    NSString *company = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    self.company = company;
    
    self.postalCode = nil;
    self.city = nil;
    self.phone = nil;
    self.countryPickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_COUNTRY" withDefaultValue:@"Select Country"];
    self.statePickerValue = [ACConstants getLocalizedStringForKey:@"SELECT_STATE" withDefaultValue:@"Select State"];
    self.addressLine1 = nil;
    self.addressLine2 = nil;
    self.selectedStateIndex = -1;
    self.selectedCountryIndex = -1;
    
    self.willShowCityAndState = YES;
    
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    int phoneCount = ABMultiValueGetCount(phones);
    if(1 <= phoneCount)
    {
        NSString *ph = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, 0);
        self.phone = ph;
    }
    if (phones) {
        CFRelease(phones);
    }
    
    ABMultiValueRef addresses = ABRecordCopyValue(person, kABPersonAddressProperty);
    self.contactAdresses = addresses;
    
    #ifndef __clang_analyzer__
    int count = ABMultiValueGetCount(self.contactAdresses);
    #endif
    if(1 == count)
    {
        [ self chooseAdressAtIndex:0];
    }
    else if(1 < count)
    {
        NSString *title = [ACConstants getLocalizedStringForKey:@"CHOOSE_AN_ADDRESS_FOR_SHIPMENT" withDefaultValue:@"Choose an Address for Shipment"];
        
        int currentDeviceOSVersion = [UIDevice currentDevice].systemVersion.intValue;
        if(currentDeviceOSVersion < 8)// For iOS 7 versions
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                     delegate:self
                                                            cancelButtonTitle:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?nil:[ACConstants getLocalizedStringForKey:@"CANCEL" withDefaultValue:@"Cancel"]
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil, nil];
            
            for (CFIndex i = 0; i < ABMultiValueGetCount(self.contactAdresses); i++)
            {
                CFStringRef labelStringRef = ABMultiValueCopyLabelAtIndex(self.contactAdresses, i);
                //mkl localizing label
                NSString *phoneLabelLocalized = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(labelStringRef);
                NSString *labelName = [NSString stringWithFormat:@"%@",phoneLabelLocalized];
                CFRelease(labelStringRef);
                labelName = [ labelName stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                labelName = [ labelName stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
                //NSLog(@"add button: %@", labelName);
                [actionSheet addButtonWithTitle:labelName];
            }
            actionSheet.tag = 888;
            [actionSheet showInView:[UIApplication sharedApplication].keyWindow];

        }
        else // For iOS 8
        {
            UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:nil];
            
            for (CFIndex i = 0; i < ABMultiValueGetCount(self.contactAdresses); i++)
            {
                CFStringRef labelStringRef = ABMultiValueCopyLabelAtIndex(self.contactAdresses, i);

                NSString *phoneLabelLocalized = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(labelStringRef);
                NSString *labelName = [NSString stringWithFormat:@"%@",phoneLabelLocalized];
                CFRelease(labelStringRef);
                
                labelName = [ labelName stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                labelName = [ labelName stringByReplacingOccurrencesOfString:@">!$_" withString:@""];

                [anAlert addButtonWithTitle:labelName];
            }
            
            anAlert.tag = 888;
            
            [anAlert show];
        }

    }
    
    [self.shippingAddressTableView reloadData];
    
    //Advance to the first required cell:
    if ([self.nameField.text length] < 1) {
        [self.nameField becomeFirstResponder];
        return;
    }
    if ([self.addressLine1Field.text length] < 1) {
        [self.addressLine1Field becomeFirstResponder];
        return;
    }
    if ([self.cityField.text length] < 1) {
        [self.cityField becomeFirstResponder];
        return;
    }
    
    if ([self.stateField.text length] < 1) {
        [self.stateField becomeFirstResponder];
        return;
    }
    if ([self.postalCodeField.text length] < 1) {
        [self.postalCodeField becomeFirstResponder];
        return;
    }
    
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
//CS:Fixing the iOS 8 
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    switch (self.contactPickeMode) {
        case ContactPickeModeName:
            [self populateDataWithPerson:person];
            break;
        case ContactPickeModeEmail:
            [self populateEmailWithPerson:person];
        case ContactPickeModeSignup:
            [self populateDataForSignup:person];

        default:
            break;
    }
    
    //[peoplePicker dismissModalViewControllerAnimated:YES];
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

//!-- CS:iOS 8 new methods of ABPeopleNavigationController
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if(self.contactPickeMode == ContactPickeModeName)
    {
        [self populateDataWithPerson:person];
    }
    else
    {
        [self populateEmailWithPerson:person];
    }
    
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return NO;
}

#pragma - ACiPhoneLoginViewController Delegate

- (void)loginSuccess
{
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"loginSuccess");
}

- (void)loginFailure
{
    NSLog(@"loginFailure");
}

#pragma Login Related Methods

-(BOOL) validateFormForSignUp
{
    [self.fieldErrors removeAllObjects];
    //NSLog(@"validateForm email: %@ password: %@ confirmPassword: %@", self.email, self.password, self.confirmPassword);
    
    if( ![self.email validateAsEmail]){
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a valid email address", @"Please enter a valid email address")
                             forKey:[NSNumber numberWithInt:0]];
    }
    if( [self.password isEmpty]){
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                             forKey:[NSNumber numberWithInt:1]];
    }
    if( [self.confirmPassword isEmpty]){
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                             forKey:[NSNumber numberWithInt:2]];
    }
    
    if(((self.password.length > 0)&&(self.password.length < 7)) || ((self.confirmPassword.length > 0)&&(self.confirmPassword.length < 7))){
        
        UIAlertView *passLengthAlert = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"PASSWORD_AT_LEAST_SEVEN", nil) message:nil delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [passLengthAlert show];
        
        self.password = self.confirmPassword = @"";
        
        [self.fieldErrors setObject:ACLocalizedString(@"PASSWORD_AT_LEAST_SEVEN", @"PASSWORD_AT_LEAST_SEVEN")
                             forKey:[NSNumber numberWithInt:1]];
        
        [self.fieldErrors setObject:ACLocalizedString(@"PASSWORD_AT_LEAST_SEVEN", @"PASSWORD_AT_LEAST_SEVEN")
                             forKey:[NSNumber numberWithInt:2]];
        
        return NO;
        
    }
    
    if(ACIsStringWithAnyText(self.password ) &&
       ACIsStringWithAnyText(self.confirmPassword ) &&
       ![self.password isEqualToString:self.confirmPassword]) {
        
        self.error = ACLocalizedString(@"Your passwords did not match", @"Your passwords did not match");
        
        UIAlertView *passMatchAlert = [[UIAlertView alloc] initWithTitle:self.error message:nil delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [passMatchAlert show];
        
        self.password = self.confirmPassword = @"";
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                             forKey:[NSNumber numberWithInt:1]];
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                             forKey:[NSNumber numberWithInt:2]];
    }
    
    return ( [self.fieldErrors count]>0 || ACIsStringWithAnyText(self.error))?NO:YES;
}


-(BOOL) validateFormForLogin
{
    [self.fieldErrors removeAllObjects];
    
    if( ![self.email validateAsEmail]){
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a valid email address", @"Please enter a valid email address")
                             forKey:[NSNumber numberWithInt:0]];
    }
    if( [self.password isEmpty]){
        [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                             forKey:[NSNumber numberWithInt:1]];
    }
    //NSLog(@"fieldErrors: %@", self.fieldErrors);
    
    return ( [self.fieldErrors count]>0)?NO:YES;
}

- (IBAction)cancelLogin:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)toggleSegmentedAction:(id)sender
{
    self.selectedIndexPath = [NSIndexPath indexPathForRow:-1 inSection:0];
    
    self.loginMode = !self.loginMode;
    self.error = nil;
    self.email = @"";
    self.password = @"";
    self.confirmPassword = @"";
    [self.fieldErrors removeAllObjects];
    
    if(0 == self.segmentedButton.selectedSegmentIndex)
    {
        self.loginView.hidden = NO;
        self.signupView.hidden = YES;
        self.needSignUp = NO;
    }
    else
    {
        self.loginView.hidden = YES;
        self.signupView.hidden = NO;
        self.needSignUp = YES;
    }
    [self.shippingAddressTableView reloadData];
}

- (IBAction)loginWithFacebook:(id)sender
{
    [Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_LOGIN_FACEBOOK];
    [self openSessionWithAllowLoginUI: YES];
}

- (IBAction)loginWithEmail:(id)sender
{
    //    if([self.txtActiveField isFirstResponder])
    //    {
    //        [ self.txtActiveField resignFirstResponder];
    //    }
    [self.view endEditing:YES];
    
    self.error = nil;
    
    if ([self validateFormForLogin] ){
        
        [SVProgressHUD showWithStatus:ACLocalizedString(@"AUTHENTICATING",@"AUTHENTICATING") maskType:SVProgressHUDMaskTypeClear];
        
        [ArtAPI
         requestForAccountAuthenticateWithEmailAddress:self.email
         password:self.password
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
             //[SVProgressHUD dismiss];
             
             // ANALYTICS: log event - LOG IN (completed)
             [Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_LOGIN_EMAIL];
             
             AppLocation currAppLoc = [ACConstants getCurrentAppLocation];
             if(currAppLoc==AppLocationNone){
                 NSDictionary *accountDetails = [[JSON objectForKeyNotNull:@"d"] objectForKeyNotNull:@"Account"];
                 NSDictionary *profileInfo = [accountDetails objectForKeyNotNull:@"ProfileInfo"];
                 NSString *accountId = [[profileInfo objectForKeyNotNull:@"AccountId"] stringValue];
                 
                 [[NSUserDefaults standardUserDefaults] setObject:accountId forKey:@"USER_ACCOUNT_ID"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
             }else{
                 _nextButton.enabled = YES;
                 self.shippingAddressTableView.tableHeaderView = nil;
                 NSDictionary *responseDict = [JSON objectForKeyNotNull:@"d"];
                 NSString *authTok = [responseDict objectForKeyNotNull:@"AuthenticationToken"];
                 [ArtAPI setAuthenticationToken:authTok];
                 [self populateDataWithLoginResponse:responseDict];
                 
                 [SVProgressHUD dismiss];
                 
                 // Call Delegate
                 if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginSuccess)]) {
                     [self.loginDelegate loginSuccess];
                 }
             }
         }failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
             NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
             // Failure
             [SVProgressHUD dismiss];
             
             self.error =  ACLocalizedString(@"Your email address or password is incorrect", @"Your email address or password is incorrect");
             
             self.password = self.confirmPassword = @"";
             
             [self.fieldErrors setObject:ACLocalizedString(@"Login Failed", @"Login Failed")
                                  forKey:[NSNumber numberWithInt:0]];
             
             [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                                  forKey:[NSNumber numberWithInt:1]];
             [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                                  forKey:[NSNumber numberWithInt:2]];
             
             NSString *errorMessagee = [JSON objectForKey:@"APIErrorMessage"];
             NSMutableDictionary *analyticsParams = [[NSMutableDictionary alloc] initWithCapacity:3];
             [analyticsParams setValue:[NSString stringWithFormat:@"%d",error.code] forKey:ANALYTICS_APIERRORCODE];
             [analyticsParams setValue:error.localizedDescription forKey:ANALYTICS_APIERRORMESSAGE];
             [analyticsParams setValue:[request.URL absoluteString] forKey:ANALYTICS_APIURL];
             [Analytics logGAEvent:ANALYTICS_CATEGORY_ERROR_EVENT withAction:errorMessagee withParams:analyticsParams];
             
             UIAlertView *authFailAlert = [[UIAlertView alloc] initWithTitle:self.error message:nil delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
             [authFailAlert show];
             [self.shippingAddressTableView reloadData];
         }];
    } else {
        [self.shippingAddressTableView reloadData];
    }
}

- (void)forgotPasswordForEmail:(NSString *)mail {
    
    [Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_FORGOT_PASSWORD];
    
    [self.view endEditing:YES];
    if(mail&&(![mail isKindOfClass:[NSNull class]])&&[mail validateAsEmail]){
        
        [SVProgressHUD showWithStatus:ACLocalizedString(@"RETRIEVING PASSWORD",@"RETRIEVING PASSWORD")];
        
        [ArtAPI
         accountRetrievePasswordWithEmailAddress:mail
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             //NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
             [SVProgressHUD dismiss];
             
             UIAlertView *forgotPassSuccessAlert = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"NEW_PASSWORD_SENT", nil)  message:nil delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
             [forgotPassSuccessAlert show];
             
             //             [self.navigationController popViewControllerAnimated:YES];
             
         }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
             //NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
             // Failure
             NSString *errorMessagee = [JSON objectForKey:@"APIErrorMessage"];
             NSMutableDictionary *analyticsParams = [[NSMutableDictionary alloc] initWithCapacity:3];
             [analyticsParams setValue:[NSString stringWithFormat:@"%d",error.code] forKey:ANALYTICS_APIERRORCODE];
             [analyticsParams setValue:error.localizedDescription forKey:ANALYTICS_APIERRORMESSAGE];
             [analyticsParams setValue:[request.URL absoluteString] forKey:ANALYTICS_APIURL];
             [Analytics logGAEvent:ANALYTICS_CATEGORY_ERROR_EVENT withAction:errorMessagee withParams:analyticsParams];
             
             UIAlertView *forgotPassErrorAlert = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"NO_ACCOUNT_INFO_FOUND", nil) message:nil delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
             [forgotPassErrorAlert show];
             [SVProgressHUD dismiss];
             
         }];
        
    } else {
        UIAlertView *invalidMailAlert = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"ERROR", nil) message:ACLocalizedString(@"Please enter a valid email address", @"Please enter a valid email address") delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [invalidMailAlert show];
    }
}

- (IBAction)signupWithEmail:(id)sender
{
    [Analytics logGAEvent:ANALYTICS_CATEGORY_UI_ACTION withAction:ANALYTICS_EVENT_NAME_CREATE_ACCOUNT];
    [self.view endEditing:YES];
    
    self.error = nil;
//    self.tableview.tableHeaderView = [self tableViewHeader]; jobin
    
    if ([self validateFormForSignUp] ){
        //NSLog(@"passed validation");
        [SVProgressHUD showWithStatus:ACLocalizedString(@"SIGNING UP",@"SIGNING UP")];
        
        [ArtAPI
         requestForAccountCreateWithEmailAddress:self.email
         password:self.password
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
             
             AppLocation currAppLoc = [ACConstants getCurrentAppLocation];
             if(currAppLoc==AppLocationNone){
                 NSDictionary *accountDetails = [[JSON objectForKeyNotNull:@"d"] objectForKeyNotNull:@"Account"];
                 NSDictionary *profileInfo = [accountDetails objectForKeyNotNull:@"ProfileInfo"];
                 NSString *accountId = [[profileInfo objectForKeyNotNull:@"AccountId"] stringValue];
                 
                 [[NSUserDefaults standardUserDefaults] setObject:accountId forKey:@"USER_ACCOUNT_ID"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
             }else{
                 NSDictionary *responseDict = [JSON objectForKeyNotNull:@"d"];
                 NSString *authTok = [responseDict objectForKeyNotNull:@"AuthenticationToken"];
                 [ArtAPI setAuthenticationToken:authTok];
                 
                 // Call Delegate
                 if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginSuccess)]) {
                     [self.loginDelegate loginSuccess];
                 }
             }
             
         }
         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
             NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
             // Failure
             [SVProgressHUD dismiss];
             
             self.error =  [JSON objectForKey:@"APIErrorMessage"];
             
             //try to get better error message from operation response
             NSDictionary *dDict = [JSON objectForKey:@"d"];
             
             if(dDict){
                 NSDictionary *operationResponseDict = [dDict objectForKey:@"OperationResponse"];
                 if(operationResponseDict){
                     NSArray *errorsArray = [operationResponseDict objectForKey:@"Errors"];
                     if(errorsArray){
                         
                         NSDictionary *firstError = [errorsArray objectAtIndex:0];
                         
                         if(firstError){
                             
                             NSString *errorCode = [firstError objectForKey:@"ErrorCode"];
                             NSString *errorMessage = [firstError objectForKey:@"ErrorMessage"];
                             
                             if(errorMessage){
                                 if([errorMessage length] > 0){
                                     self.error = errorMessage;
                                 }
                             }
                         }
                     }
                     
                 }
             }
             
             self.password = self.confirmPassword = @"";
             
             [self.fieldErrors setObject:ACLocalizedString(@"Account Create Failed", @"Account Create Failed")
                                  forKey:[NSNumber numberWithInt:0]];
             
             [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                                  forKey:[NSNumber numberWithInt:1]];
             [self.fieldErrors setObject:ACLocalizedString(@"Please enter a password", @"Please enter a password")
                                  forKey:[NSNumber numberWithInt:2]];
             
             NSMutableDictionary *analyticsParams = [[NSMutableDictionary alloc] initWithCapacity:3];
             [analyticsParams setValue:[NSString stringWithFormat:@"%d",error.code] forKey:ANALYTICS_APIERRORCODE];
             [analyticsParams setValue:error.localizedDescription forKey:ANALYTICS_APIERRORMESSAGE];
             [analyticsParams setValue:[request.URL absoluteString] forKey:ANALYTICS_APIURL];
             [Analytics logGAEvent:ANALYTICS_CATEGORY_ERROR_EVENT withAction:self.error withParams:analyticsParams];
             
             UIAlertView *accountCreateAlert = [[UIAlertView alloc] initWithTitle:self.error message:nil delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
             [accountCreateAlert show];
             
             [self.shippingAddressTableView reloadData];
             
         }];
        
    } else {
        //NSLog(@"failed validation");
        // Reload and display error
//        [self.tableview reloadData]; Jobin
    }
}

- (IBAction)forgotPassword:(id)sender
{
    UIAlertView *forgotPasswordAlert = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"ENTER_EMAIL_ACCOUNT", nil) message:nil delegate:self cancelButtonTitle:ACLocalizedString(@"CANCEL", nil) otherButtonTitles:ACLocalizedString(@"OK", nil), nil];
    forgotPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[forgotPasswordAlert textFieldAtIndex:0] setDelegate:self];
//    [forgotPasswordAlert textFieldAtIndex:0].tag = 100;
    [forgotPasswordAlert show];
}

- (void) authenticateWithFacebookUID:(NSString *)facebookUID
                        emailAddress:(NSString *)emailAddress
                           firstName:(NSString *)firstName
                            lastName:(NSString *)lastName
                       facebookToken:(NSString *)facebookToken {
    //NSLog(@"authenticateWithFacebookUID: %@, emailAddress: %@ firstName: %@ lastName: %@ facebookToken: %@",
    //      facebookUID, emailAddress, firstName, lastName,facebookToken);
    
    [SVProgressHUD showWithStatus:ACLocalizedString(@"AUTHENTICATING",@"AUTHENTICATING") maskType:SVProgressHUDMaskTypeClear];
    
    [ArtAPI
     requestForAccountAuthenticateWithFacebookUID:facebookUID emailAddress:emailAddress firstName:firstName lastName:lastName facebookToken:facebookToken
     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
         NSLog(@"SUCCESS url: %@ %@ json: %@", request.HTTPMethod, request.URL, JSON);
         
         AppLocation currAppLoc = [ACConstants getCurrentAppLocation];
         if(currAppLoc==AppLocationNone){
             NSDictionary *accountDetails = [[JSON objectForKeyNotNull:@"d"] objectForKeyNotNull:@"Account"];
             NSDictionary *profileInfo = [accountDetails objectForKeyNotNull:@"ProfileInfo"];
             NSString *accountId = [[profileInfo objectForKeyNotNull:@"AccountId"] stringValue];
             
             [[NSUserDefaults standardUserDefaults] setObject:accountId forKey:@"USER_ACCOUNT_ID"];
             [[NSUserDefaults standardUserDefaults] synchronize];
         }else{
             
             _nextButton.enabled = YES;
             self.shippingAddressTableView.tableHeaderView = nil;
             NSDictionary *responseDict = [JSON objectForKeyNotNull:@"d"];
             NSString *authTok = [responseDict objectForKeyNotNull:@"AuthenticationToken"];
             [ArtAPI setAuthenticationToken:authTok];
             [self populateDataWithLoginResponse:responseDict];
             
             // Call Delegate
             if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginSuccess)]) {
                 [self.loginDelegate loginSuccess];
             }
         }
         
         
     }  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
         NSLog(@"FAILURE url: %@ %@ json: %@ error: %@", request.HTTPMethod, request.URL, JSON, error);
         // Failure
         [SVProgressHUD dismiss];
         
         //NSLog(@"request failed for URL: %@", request.URL);
         if(JSON && ACIsStringWithAnyText([JSON objectForKey:@"APIErrorMessage"])){
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"Login Failed",@"Login Failed")
                                                                 message:[JSON objectForKey:@"APIErrorMessage"]
                                                                delegate:nil cancelButtonTitle:ACLocalizedString(@"OK", nil)
                                                       otherButtonTitles:nil];
             [alertView show];
         } else {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ACLocalizedString(@"An error occurred. Please try again.",@"An error occurred. Please try again.")
                                                                 message:nil
                                                                delegate:nil
                                                       cancelButtonTitle:ACLocalizedString(@"OK", nil)
                                                       otherButtonTitles:nil];
             [alertView show];
             
         }
         
         NSString *errorMessagee = [JSON objectForKey:@"APIErrorMessage"];
         NSMutableDictionary *analyticsParams = [[NSMutableDictionary alloc] initWithCapacity:3];
         [analyticsParams setValue:[NSString stringWithFormat:@"%d",error.code] forKey:ANALYTICS_APIERRORCODE];
         [analyticsParams setValue:error.localizedDescription forKey:ANALYTICS_APIERRORMESSAGE];
         [analyticsParams setValue:[request.URL absoluteString] forKey:ANALYTICS_APIURL];
         [Analytics logGAEvent:ANALYTICS_CATEGORY_ERROR_EVENT withAction:errorMessagee withParams:analyticsParams];
         
         // Call Delegate
         if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginFailure)]) {
             [self.loginDelegate loginFailure];
         }
         
     }];
}


#pragma mark -
#pragma mark Facebook
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    BOOL result = NO;
    //    if(!FBSession.activeSession.isOpen){
    FBSession *session = nil;
    if([ACConstants isArtCircles]){
        session =
        [[FBSession alloc] initWithAppID:nil
                             permissions:nil
                         urlSchemeSuffix:@"artcircles"
                      tokenCacheStrategy:nil];
    }else{
        session =
        [[FBSession alloc] initWithAppID:nil
                             permissions:[NSArray arrayWithObjects:@"user_photos",@"email",nil]
                         defaultAudience:FBSessionDefaultAudienceFriends
                         urlSchemeSuffix:nil
                      tokenCacheStrategy:nil];
    }
    
    if (allowLoginUI ||
        (session.state == FBSessionStateCreatedTokenLoaded)) {
        [FBSession setActiveSession:session];
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             [self sessionStateChanged:session state:state error:error];
         }];
        result = session.isOpen;
    }
    //    }else{
    //        [self handleFacebookLogin];
    //    }
    
    return result;
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    //NSLog(@"sessionStateChanged: %@ state: %d error: %@", session, state, error );
    
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                //NSLog(@"User session found");
                [self handleFacebookLogin];
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    if (error) {
        NSString* message = error.localizedDescription;
        
        if(error.code == 2){
            NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
            NSString * key = @"com.facebook.error.code.2";
            message = [NSString stringWithFormat:ACLocalizedString(key,key), appName];
        }
        
        NSString *errorTitleString = [ACConstants getLocalizedStringForKey:@"ERROR" withDefaultValue:@"Error"];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:errorTitleString
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:ACLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void) handleFacebookLogin {
    FBAccessTokenData * accessTokenData = [FBSession activeSession].accessTokenData;
    //NSLog(@"handleFacebookLogin accessTokenData: %@", accessTokenData);
    
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 //NSLog(@"ACLoginViewController.got user info: %@", user );
                 
                 if(user && accessTokenData){
                     [self authenticateWithFacebookUID:[user objectForKey:@"id"]
                                          emailAddress:[user objectForKey:@"email"]
                                             firstName:[user objectForKey:@"first_name"]
                                              lastName:[user objectForKey:@"last_name"]
                                         facebookToken:accessTokenData.accessToken];
                 }else{
                     NSLog(@"Either no FB user or accesstokendata");
                 }
                 
             } else {
                 NSLog(@"error: %@", error);
             }
         }];
        
    }
}


@end
