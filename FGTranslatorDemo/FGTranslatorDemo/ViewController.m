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

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

- (IBAction)translate:(id)sender
{
    static NSString *GOOGLE_API_KEY = @"your_key";
    
    static NSString *BING_CLIENT_ID = @"your_id";
    static NSString *BING_CLIENT_SECRET = @"your_secret";
    
    FGTranslator *translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    translator.preferSourceGuess = NO;
    [translator translateText:@"Bonjour monsieur, comment ca va?"
                   withSource:nil
                       target:nil
                   completion:^(NSError *error, NSString *translated, NSString *source)
     {
         if (error)
             NSLog(@"error:%@", error);
         else
             NSLog(@">>trans (%@): %@", source, translated);
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
