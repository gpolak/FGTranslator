//
//  FGTranslateRequest.h
//  FGTranslatorDemo
//
//  Created by George Polak on 8/12/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

extern NSString *const FG_TRANSLATOR_ERROR_DOMAIN;

typedef NSInteger FGTranslationError;

enum
{
    FGTranslationErrorNoToken = 0,
    FGTranslationErrorBadRequest = 1,
    FGTranslationErrorOther = 2
};


@interface FGTranslateRequest : NSObject

/**
 Performs a translation with Google API.
 
 @params
 message: text to translate
 source: source text ISO language code (pass nil to guess)
 target: language to translate to (ISO language code)
 key: Google API key
 completion: completion handler
 
 @returns
 Token instance.
 */
+ (AFHTTPRequestOperation *)googleTranslateMessage:(NSString *)message
                                        withSource:(NSString *)source
                                            target:(NSString *)target
                                               key:(NSString *)key
                                        completion:(void (^)(NSString *translatedMessage, NSString *detectedSource, NSError *error))completion;

/**
 Performs a translation with Bing API.
 
 @params
 message: text to translate
 source: source text ISO language code (pass nil to guess)
 target: language to translate to (ISO language code)
 clientId: Azure client ID
 clientSecret: Azure client secret
 completion: completion handler
 
 @returns
 Token instance.
 */
+ (AFHTTPRequestOperation *)bingTranslateMessage:(NSString *)message
                                      withSource:(NSString *)source
                                          target:(NSString *)target
                                        clientId:(NSString *)clientId
                                    clientSecret:(NSString *)clientSecret
                                      completion:(void (^)(NSString *translatedMessage, NSString *detectedSource, NSError *error))completion;

+ (void)flushCredentials;

@end
