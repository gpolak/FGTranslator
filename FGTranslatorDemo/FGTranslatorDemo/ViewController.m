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
    static NSString *GOOGLE_API_KEY = @"AIzaSyChjS0m1xD-8ZLOiVeQT0Ul01mDaEVo3iQ";
    translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    
    // using Bing Translate
//    static NSString *BING_CLIENT_ID = @"your_id_here";
//    static NSString *BING_CLIENT_SECRET = @"your_secret_here";
//    translator = [[FGTranslator alloc] initWithBingAzureClientId:BING_CLIENT_ID secret:BING_CLIENT_SECRET];
    
    [translator translateText:self.textView.text
                   completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
     {
         if (error)
         {
             [self showErrorWithError:error];
             
             [self.spinner stopAnimating];
             sender.hidden = NO;
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
             
             [self.spinner stopAnimating];
             sender.hidden = NO;
         }
     }];
}
- (IBAction)detect:(UIButton *)sender
{
    [self.textView resignFirstResponder];
    
    sender.hidden = YES;
    [self.spinner startAnimating];
    
    FGTranslator *translator;
    
    // using Google Translate
    static NSString *GOOGLE_API_KEY = @"AIzaSyChjS0m1xD-8ZLOiVeQT0Ul01mDaEVo3iQ";
    translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    
    // using Bing Translate
//    static NSString *BING_CLIENT_ID = @"fgtranslator_test";
//    static NSString *BING_CLIENT_SECRET = @"rh8xDMZFTktKAfAZj79cuuHaWR3+zCA49JC3YPf6RVY=";
//    translator = [[FGTranslator alloc] initWithBingAzureClientId:BING_CLIENT_ID secret:BING_CLIENT_SECRET];
    
    [translator detectLanguage:self.textView.text completion:^(NSError *error, NSString *detectedSource, float confidence) {
        if (error)
        {
            [self showErrorWithError:error];
            
            [self.spinner stopAnimating];
            sender.hidden = NO;
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
            
            [self.spinner stopAnimating];
            sender.hidden = NO;
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
