//
//  FGTranslateRequest.m
//  FGTranslatorDemo
//
//  Created by George Polak on 8/12/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import "FGTranslateRequest.h"
#import "FGAzureToken.h"
#import "NSString+FGTranslator.h"
#import "XMLDictionary.h"
#import "FGTranslator.h"

@implementation FGTranslateRequest

NSString *const FG_TRANSLATOR_ERROR_DOMAIN = @"FGTranslatorErrorDomain";

NSString *const FG_TRANSLATOR_AZURE_TOKEN = @"FG_TRANSLATOR_AZURE_TOKEN";
NSString *const FG_TRANSLATOR_AZURE_TOKEN_EXPIRY = @"FG_TRANSLATOR_AZURE_TOKEN_EXPIRY";


#pragma mark - Google

+ (AFHTTPRequestOperation *)googleTranslateMessage:(NSString *)message
                                      withSource:(NSString *)source
                                          target:(NSString *)target
                                               key:(NSString *)key
                                         quotaUser:(NSString *)quotaUser
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
    
    // quota
    if (quotaUser.length > 0)
        [queryString appendFormat:@"&quotaUser=%@", quotaUser];
    
    // message
    [queryString appendFormat:@"&q=%@", [NSString urlEncodedStringFromString:message]];
    
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
        NSLog(@"FGTranslator: failed Google translate: %@", operation.responseObject);
        
        NSInteger code = error.code == 400 ? FGTranslationErrorBadRequest : FGTranslationErrorOther;
        NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:code userInfo:nil];
        
        completion(nil, nil, fgError);
    }];
    [operation start];
    
    return operation;
}

+ (AFHTTPRequestOperation *)googleDetectLanguage:(NSString *)text
                                             key:(NSString *)key
                                       quotaUser:(NSString *)quotaUser
                                      completion:(void (^)(NSString *detectedSource, float confidence, NSError *error))completion
{
    NSURL *base = [NSURL URLWithString:@"https://www.googleapis.com/language/translate/v2/detect"];
    
    NSMutableString *queryString = [NSMutableString string];
    // API key
    [queryString appendFormat:@"?key=%@", key];
    // output style
    [queryString appendString:@"&format=text"];
    [queryString appendString:@"&prettyprint=false"];
    
    // quota
    if (quotaUser.length > 0)
        [queryString appendFormat:@"&quotaUser=%@", quotaUser];
    
    // message
    [queryString appendFormat:@"&q=%@", [NSString urlEncodedStringFromString:text]];
    
    NSURL *requestURL = [NSURL URLWithString:queryString relativeToURL:base];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *translation = [[[[responseObject objectForKey:@"data"] objectForKey:@"detections"] objectAtIndex:0] objectAtIndex:0];
         NSString *detectedSource = [translation objectForKey:@"language"];
         float confidence = [[translation objectForKey:@"confidence"] floatValue];
         
         completion(detectedSource, confidence, nil);
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"FGTranslator: failed Google language detect: %@", operation.responseObject);
         
         NSInteger code = error.code == 400 ? FGTranslationErrorBadRequest : FGTranslationErrorOther;
         NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:code userInfo:nil];
         
         completion(nil, FGTranslatorUnknownConfidence, fgError);
     }];
    [operation start];
    
    return operation;
}

+ (AFHTTPRequestOperation *)googleSupportedLanguagesWithKey:(NSString *)key
                                                  quotaUser:(NSString *)quotaUser
                                                 completion:(void (^)(NSArray *languageCodes, NSError *error))completion
{
    NSURL *base = [NSURL URLWithString:@"https://www.googleapis.com/language/translate/v2/languages"];
    
    NSMutableString *queryString = [NSMutableString string];
    // API key
    [queryString appendFormat:@"?key=%@", key];
    // output style
    [queryString appendString:@"&format=text"];
    [queryString appendString:@"&prettyprint=false"];
    
    // quota
    if (quotaUser.length > 0)
        [queryString appendFormat:@"&quotaUser=%@", quotaUser];
    
    NSURL *requestURL = [NSURL URLWithString:queryString relativeToURL:base];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSMutableArray *languageCodes = [NSMutableArray new];
        
        NSArray *languages = [[responseObject objectForKey:@"data"] objectForKey:@"languages"];
        for (NSDictionary *element in languages)
        {
            NSString *code = [element objectForKey:@"language"];
            if (code.length > 0)
                [languageCodes addObject:code];
        }
         
        completion(languageCodes, nil);
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"FGTranslator: failed Google supported languages: %@", operation.responseObject);
         
         NSInteger code = error.code == 400 ? FGTranslationErrorBadRequest : FGTranslationErrorOther;
         NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:code userInfo:nil];
         
         completion(nil, fgError);
     }];
    [operation start];
    
    return operation;
}


#pragma mark - Bing

+ (AFHTTPRequestOperation *)bingTranslateMessage:(NSString *)message
                                      withSource:(NSString *)source
                                          target:(NSString *)target
                                        clientId:(NSString *)clientId
                                    clientSecret:(NSString *)clientSecret
                                      completion:(void (^)(NSString *translatedMessage, NSString *detectedSource, NSError *error))completion
{
    FGAzureToken *token = [FGTranslateRequest azureToken];
    if ([token isValid])
    {
        return [FGTranslateRequest doBingTranslateMessage:message
                                               withSource:source
                                                   target:target
                                                    token:token
                                               completion:completion];
    }
    else
    {
        __block AFHTTPRequestOperation *operation;
        operation = [FGTranslateRequest getBingAuthTokenWithId:clientId secret:clientSecret completion:^(FGAzureToken *token, NSError *error) {
            if (!error)
            {
                [FGTranslateRequest setAzureToken:token];
                operation = [FGTranslateRequest doBingTranslateMessage:message withSource:source target:target token:token completion:completion];
            }
            else
            {
                NSLog(@"FGTranslator: failed Bing translate: %@", operation.responseObject);
                
                NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:FGTranslationErrorNoToken userInfo:error.userInfo];
                completion(nil, nil, fgError);
            }
        }];
        
        return operation;
    }
}

+ (AFHTTPRequestOperation *)bingDetectLanguage:(NSString *)message
                                      clientId:(NSString *)clientId
                                  clientSecret:(NSString *)clientSecret
                                    completion:(void (^)(NSString *detectedLanguage, float confidence, NSError *error))completion
{
    FGAzureToken *token = [FGTranslateRequest azureToken];
    if ([token isValid])
    {
        return [FGTranslateRequest doBingDetectLanguage:message
                                                  token:token
                                             completion:completion];
    }
    else
    {
        __block AFHTTPRequestOperation *operation;
        operation = [FGTranslateRequest getBingAuthTokenWithId:clientId secret:clientSecret completion:^(FGAzureToken *token, NSError *error) {
            if (!error)
            {
                [FGTranslateRequest setAzureToken:token];
                operation = [FGTranslateRequest doBingDetectLanguage:message
                                                               token:token
                                                          completion:completion];
            }
            else
            {
                NSLog(@"FGTranslator: failed Bing language detection: %@", operation.responseObject);
                
                NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:FGTranslationErrorNoToken userInfo:error.userInfo];
                completion(nil, 0, fgError);
            }
        }];
        
        return operation;
    }
}

+ (AFHTTPRequestOperation *)bingSupportedLanguagesWithClienId:(NSString *)clientId
                                                 clientSecret:(NSString *)clientSecret
                                                   completion:(void (^)(NSArray *languageCodes, NSError *error))completion
{
    FGAzureToken *token = [FGTranslateRequest azureToken];
    if ([token isValid])
    {
        return [FGTranslateRequest doBingSupportedLanguagesWithToken:token completion:completion];
    }
    else
    {
        __block AFHTTPRequestOperation *operation;
        operation = [FGTranslateRequest getBingAuthTokenWithId:clientId secret:clientSecret completion:^(FGAzureToken *token, NSError *error) {
            if (!error)
            {
                [FGTranslateRequest setAzureToken:token];
                operation = [FGTranslateRequest doBingSupportedLanguagesWithToken:token completion:completion];
            }
            else
            {
                NSLog(@"FGTranslator: failed Bing supported languages:%@", operation.responseObject);
                
                NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:FGTranslationErrorNoToken userInfo:error.userInfo];
                completion(nil, fgError);
            }
        }];
        
        return operation;
    }
}

+ (AFHTTPRequestOperation *)doBingTranslateMessage:(NSString *)message
                                        withSource:(NSString *)source
                                            target:(NSString *)target
                                             token:(FGAzureToken *)token
                                        completion:(void (^)(NSString *translatedMessage, NSString *detectedSource, NSError *error))completion
{
    NSURL *base = [NSURL URLWithString:@"http://api.microsofttranslator.com/V2/Http.svc/Translate"];
    
    NSMutableString *queryString = [NSMutableString string];
    
    // target language
    [queryString appendFormat:@"?to=%@", target];
    
    // source language
    if (source)
        [queryString appendFormat:@"&from=%@", source];
    
    // message
    [queryString appendFormat:@"&text=%@", [NSString urlEncodedStringFromString:message]];
    
    [queryString appendString:@"&contentType=text/plain"];
    
    NSURL *requestURL = [NSURL URLWithString:queryString relativeToURL:base];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    
    NSString *authString = [NSString stringWithFormat:@"bearer %@", token.token];
    [request setValue:authString forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        XMLDictionaryParser *parser = [XMLDictionaryParser sharedInstance];
        NSDictionary *dict = [parser dictionaryWithParser:responseObject];
        completion([dict innerText], nil, nil);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:FGTranslationErrorOther userInfo:error.userInfo];
        completion(nil, nil, fgError);
    }];
    
    [operation start];
    return operation;
}

+ (AFHTTPRequestOperation *)doBingDetectLanguage:(NSString *)message
                                           token:(FGAzureToken *)token
                                      completion:(void (^)(NSString *detectedSource, float confidence, NSError *error))completion
{
    NSURL *base = [NSURL URLWithString:@"http://api.microsofttranslator.com/V2/Http.svc/Detect"];
    
    NSMutableString *queryString = [NSMutableString string];
    
    // message
    [queryString appendFormat:@"?text=%@", [NSString urlEncodedStringFromString:message]];
    
    NSURL *requestURL = [NSURL URLWithString:queryString relativeToURL:base];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    
    NSString *authString = [NSString stringWithFormat:@"bearer %@", token.token];
    [request setValue:authString forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        XMLDictionaryParser *parser = [XMLDictionaryParser sharedInstance];
        NSDictionary *dict = [parser dictionaryWithParser:responseObject];
        completion([dict innerText], FGTranslatorUnknownConfidence, nil);
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:FGTranslationErrorOther userInfo:error.userInfo];
        completion(nil, FGTranslatorUnknownConfidence, fgError);
    }];
    
    [operation start];
    return operation;
}

+ (AFHTTPRequestOperation *)doBingSupportedLanguagesWithToken:(FGAzureToken *)token
                                                   completion:(void (^)(NSArray *languageCodes, NSError *error))completion
{
    NSURL *base = [NSURL URLWithString:@"http://api.microsofttranslator.com/V2/Http.svc/GetLanguagesForTranslate"];
    
    NSMutableString *queryString = [NSMutableString string];
    
    NSURL *requestURL = [NSURL URLWithString:queryString relativeToURL:base];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    
    NSString *authString = [NSString stringWithFormat:@"bearer %@", token.token];
    [request setValue:authString forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        XMLDictionaryParser *parser = [XMLDictionaryParser sharedInstance];
        NSDictionary *dict = [parser dictionaryWithParser:responseObject];
        NSArray *codes = [dict objectForKey:@"string"];
        completion(codes, nil);
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
         NSError *fgError = [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:FGTranslationErrorOther userInfo:error.userInfo];
         completion(nil, fgError);
    }];
    
    [operation start];
    return operation;
}

+ (AFHTTPRequestOperation *)getBingAuthTokenWithId:(NSString *)clientId
                                            secret:(NSString *)clientSecret
                                        completion:(void (^)(FGAzureToken *token, NSError *error))completion
{
    NSURL *base = [NSURL URLWithString:@"https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"];
    
    NSMutableString *queryString = [NSMutableString string];
    [queryString appendFormat:@"client_id=%@", clientId];
    [queryString appendFormat:@"&client_secret=%@", [NSString urlEncodedStringFromString:clientSecret]];
    [queryString appendString:@"&scope=http://api.microsofttranslator.com"];
    [queryString appendString:@"&grant_type=client_credentials"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:base];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSString *token = [responseObject objectForKey:@"access_token"];
        NSTimeInterval expiry = [[responseObject objectForKey:@"expires_in"] doubleValue];
        NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:expiry];
        
        FGAzureToken *azureToken = [[FGAzureToken alloc] initWithToken:token expiry:expiration];
        
        completion(azureToken, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        completion(nil, error);
    }];
    [operation start];
    
    return operation;
}


#pragma mark - Misc

+ (void)flushCredentials
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:FG_TRANSLATOR_AZURE_TOKEN];
    [defaults removeObjectForKey:FG_TRANSLATOR_AZURE_TOKEN_EXPIRY];
    [defaults synchronize];
}

+ (void)setAzureToken:(FGAzureToken *)azureToken
{
    if (!azureToken)
        return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:azureToken.token forKey:FG_TRANSLATOR_AZURE_TOKEN];
    [defaults setObject:azureToken.expiry forKey:FG_TRANSLATOR_AZURE_TOKEN_EXPIRY];
    [defaults synchronize];
}

+ (FGAzureToken *)azureToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults stringForKey:FG_TRANSLATOR_AZURE_TOKEN];
    NSDate *expiry = [defaults objectForKey:FG_TRANSLATOR_AZURE_TOKEN_EXPIRY];
    
    return [[FGAzureToken alloc] initWithToken:token expiry:expiry];
}

@end
