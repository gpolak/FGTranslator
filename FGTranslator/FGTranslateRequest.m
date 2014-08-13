//
//  FGTranslateRequest.m
//  FGTranslatorDemo
//
//  Created by George Polak on 8/12/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import "FGTranslateRequest.h"
#import <AFNetworking.h>

@implementation FGTranslateRequest

NSString *const FG_TRANSLATOR_ERROR_DOMAIN = @"FarGateTranslationErrorDomain";

+ (void)googleTranslateMessage:(NSString *)message
                    withSource:(NSString *)source
                        target:(NSString *)target
                           key:(NSString *)key
                    completion:(void (^)(NSString *translatedMessage, NSString *detectedSource, NSError *error))completion
{    
    NSURL *base = [NSURL URLWithString:@"https://www.googleapis.com/language/translate/v2"];
    
    NSMutableString *queryString = [NSMutableString string];
    // API key
    [queryString appendFormat:@"?key=%@", key];
    // output style
    [queryString appendString:@"&format=text"];
    [queryString appendString:@"&prettyprint=false"];
    
    // source language
    if (source)
        [queryString appendFormat:@"&source=%@", source];
    
    // target language
    [queryString appendFormat:@"&target=%@", target];
    
    // message
    [queryString appendFormat:@"&q=%@", [FGTranslateRequest urlEncodedStringFromString:message]];
    
    NSURL *requestURL = [NSURL URLWithString:queryString relativeToURL:base];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *translation = [[[responseObject objectForKey:@"data"] objectForKey:@"translations"] objectAtIndex:0];
        NSString *translatedText = [translation objectForKey:@"translatedText"];
        NSString *detectedSource = [translation objectForKey:@"detectedSourceLanguage"];
        if (!detectedSource)
            detectedSource = source;
        
        completion(translatedText, detectedSource, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSInteger code = error.code == 400 ? FGTranslationErrorBadRequest : FGTranslationErrorOther;
        NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:code userInfo:nil];
        
        completion(nil, nil, fgError);
    }];
    [operation start];
}


#pragma mark - Utils

+ (NSString *)urlEncodedStringFromString:(NSString *)original
{
    NSMutableString *escaped = [NSMutableString stringWithString:[original stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [escaped replaceOccurrencesOfString:@"$" withString:@"%24" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    
    return escaped;
}

@end
