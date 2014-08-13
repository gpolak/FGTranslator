//
//  ViewController.m
//  FGTranslatorDemo
//
//  Created by George Polak on 8/12/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import "ViewController.h"

#import "FGTranslator.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // pre-load the text view
    self.textView.text = @"Bonjour!";
    [self.spinner stopAnimating];
}

- (IBAction)translate:(UIButton *)sender
{
    [self.textView resignFirstResponder];
    
    sender.hidden = YES;
    [self.spinner startAnimating];
    
    FGTranslator *translator;
    
    // using Google Translate
    static NSString *GOOGLE_API_KEY = @"your_key_here";
    translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    
    // using Bing Translate
//    static NSString *BING_CLIENT_ID = @"your_id_here";
//    static NSString *BING_CLIENT_SECRET = @"your_secret_here";
//    translator = [[FGTranslator alloc] initWithBingAzureClientId:BING_CLIENT_ID secret:BING_CLIENT_SECRET];
    
    [translator translateText:self.textView.text
                   completion:^(NSError *error, NSString *translated, NSString *source)
     {
         if (error)
         {
             NSLog(@"FGTranslator failed with error: %@", error);
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:error.localizedDescription
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK" otherButtonTitles:nil];
             [alert show];
             
             [self.spinner stopAnimating];
             sender.hidden = NO;
         }
         else
         {
             NSString *fromLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:source];
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:fromLanguage ? [NSString stringWithFormat:@"from %@", fromLanguage] : nil
                                                             message:translated
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
             
             [self.spinner stopAnimating];
             sender.hidden = NO;
         }
     }];
}

@end
