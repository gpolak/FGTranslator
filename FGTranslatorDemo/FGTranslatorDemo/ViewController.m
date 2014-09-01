//
//  ViewController.m
//  FGTranslatorDemo
//
//  Created by George Polak on 8/12/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import "ViewController.h"

#import "FGTranslator.h"
#import "SVProgressHUD.h"

static NSString *const GOOGLE_API_KEY = nil;
static NSString *const BING_CLIENT_ID = nil;
static NSString *const BING_CLIENT_SECRET = nil;

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // pre-load the text view
    self.textView.text = @"Bonjour!";
    
    // not needed in production code, but making sure the demo is clean on each run
    [FGTranslator flushCache];
    [FGTranslator flushCredentials];
}

- (IBAction)translate:(UIButton *)sender
{
    [SVProgressHUD show];
    
    [self.textView resignFirstResponder];
    
    FGTranslator *translator;
    
    // using Google Translate
    translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    
    // using Bing Translate
    // translator = [[FGTranslator alloc] initWithBingAzureClientId:BING_CLIENT_ID secret:BING_CLIENT_SECRET];
    
    [translator translateText:self.textView.text
                   completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
    {
         if (error)
         {
             [self showErrorWithError:error];
             
             [SVProgressHUD dismiss];
         }
         else
         {
             NSString *fromLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:sourceLanguage];
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:fromLanguage ? [NSString stringWithFormat:@"from %@", fromLanguage] : nil
                                                             message:translated
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
             [alert show];
             
             [SVProgressHUD dismiss];
         }
     }];
}

- (IBAction)detect:(UIButton *)sender
{
    [SVProgressHUD show];
    
    [self.textView resignFirstResponder];
    
    FGTranslator *translator;
    
    // using Google Translate
    translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    
    // using Bing Translate
    // translator = [[FGTranslator alloc] initWithBingAzureClientId:BING_CLIENT_ID secret:BING_CLIENT_SECRET];
    
    [translator detectLanguage:self.textView.text completion:^(NSError *error, NSString *detectedSource, float confidence)
    {
        if (error)
        {
            [self showErrorWithError:error];
            
            [SVProgressHUD dismiss];
        }
        else
        {
            NSString *fromLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:detectedSource];
            
            NSString *confidenceMessage = confidence == FGTranslatorUnknownConfidence
                ? @"unknown confidence"
                : [NSString stringWithFormat:@"%.1f%% sure", confidence * 100];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:fromLanguage
                                                            message:confidenceMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            [SVProgressHUD dismiss];
        }
    }];
}

- (IBAction)supportedLanguages:(id)sender
{
    [SVProgressHUD show];
    
    [self.textView resignFirstResponder];
    
    FGTranslator *translator;
    
    // using Google Translate
    translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    
    // using Bing Translate
    // translator = [[FGTranslator alloc] initWithBingAzureClientId:BING_CLIENT_ID secret:BING_CLIENT_SECRET];
    
    [translator supportedLanguages:^(NSError *error, NSArray *languageCodes)
    {
        if (error)
        {
            [self showErrorWithError:error];
            
            [SVProgressHUD dismiss];
        }
        else
        {
            NSMutableString *languageMessage = [NSMutableString new];
            NSLocale *locale = [NSLocale currentLocale];
            for (NSString *code in languageCodes)
                [languageMessage appendFormat:@"%@\n", [locale displayNameForKey:NSLocaleIdentifier value:code]];
           
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%i Supported Languages", languageCodes.count]
                                                            message:languageMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            [SVProgressHUD dismiss];
        }
    }];
}

- (void)showErrorWithError:(NSError *)error
{
    NSLog(@"FGTranslator failed with error: %@", error);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
