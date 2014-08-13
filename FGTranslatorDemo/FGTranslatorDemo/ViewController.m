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
    
    static NSString *GOOGLE_API_KEY = @"your_key_here";
    
    FGTranslator *translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_API_KEY];
    [translator translateText:@"Bonjour"
                   withSource:nil
                       target:nil
                   completion:^(NSError *error, NSString *translated, NSString *source)
    {
        NSLog(@">>trans: %@", translated);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
