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

- (FGTranslator *)translator {
    /*
     * using Bing Translate
     *
     * Note: The client id and secret here is very limited and is included for demo purposes only.
     * You must use your own credentials for production apps.
     */
    FGTranslator *translator = [[FGTranslator alloc] initWithBingAzureClientId:@"fgtranslator-demo" secret:@"GrsgBiUCKACMB+j2TVOJtRboyRT8Q9WQHBKJuMKIxsU="];
    
    // or use Google Translate
    
    // using Google Translate
    // translator = [[FGTranslator alloc] initWithGoogleAPIKey:@"your_google_key"];
    
    return translator;
}

- (NSLocale *)currentLocale {
    NSLocale *locale = [NSLocale currentLocale];
#if TARGET_IPHONE_SIMULATOR
    // handling Apple bug
    // http://stackoverflow.com/a/26769277/211692
    return [NSLocale localeWithLocaleIdentifier:[locale localeIdentifier]];
#else
    return locale;
#endif
}

- (IBAction)translate:(UIButton *)sender
{
    [SVProgressHUD show];
    
    [self.textView resignFirstResponder];
    
    [self.translator translateText:self.textView.text
                   completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
    {
         if (error)
         {
             [self showErrorWithError:error];
             
             [SVProgressHUD dismiss];
         }
         else
         {
             NSString *fromLanguage = [[self currentLocale] displayNameForKey:NSLocaleIdentifier value:sourceLanguage];
             
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
    
    
    [self.translator detectLanguage:self.textView.text completion:^(NSError *error, NSString *detectedSource, float confidence)
    {
        if (error)
        {
            [self showErrorWithError:error];
            
            [SVProgressHUD dismiss];
        }
        else
        {
            NSString *fromLanguage = [[self currentLocale] displayNameForKey:NSLocaleIdentifier value:detectedSource];
            
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
    
    [self.translator supportedLanguages:^(NSError *error, NSArray *languageCodes)
    {
        if (error)
        {
            [self showErrorWithError:error];
            
            [SVProgressHUD dismiss];
        }
        else
        {
            NSMutableString *languageMessage = [NSMutableString new];
            NSLocale *locale = [self currentLocale];
            for (NSString *code in languageCodes)
                [languageMessage appendFormat:@"%@\n", [locale displayNameForKey:NSLocaleIdentifier value:code]];
           
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%ld Supported Languages", (long)languageCodes.count]
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
