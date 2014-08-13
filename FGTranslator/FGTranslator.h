//
//  FGTranslator.h
//  Fargate
//
//  Created by George Polak on 1/14/13.
//
//

#import <Foundation/Foundation.h>

typedef NSInteger FGTranslatorError;

enum FGTranslatorError
{
    FGTranslatorErrorUnableToTranslate = 0,
    FGTranslatorErrorNetworkError = 1,
    FGTranslatorErrorSame = 2,
    FGTranslatorErrorTranslationInProgress = 3,
    FGTranslatorErrorAlreadyTranslated = 4,
};

@interface FGTranslator : NSObject
{
    // TODO: is this needed?
    __strong FGTranslator *_retained_self;
}

@property (nonatomic) BOOL preferSourceGuess;

@property (nonatomic, readonly) NSString *googleAPIKey;
@property (nonatomic, readonly) NSString *azureClientId;
@property (nonatomic, readonly) NSString *azureClientSecret;

typedef void (^FGTranslatorCompletionHandler)(NSError *error, NSString *translated, NSString *source);

- (id)initWithGoogleAPIKey:(NSString *)key;
- (id)initWithBingAzureClientId:(NSString *)clientId secret:(NSString *)secret;

- (void)translateText:(NSString *)text
           completion:(FGTranslatorCompletionHandler)completion;

- (void)translateText:(NSString *)text
           withSource:(NSString *)source
               target:(NSString *)target
           completion:(FGTranslatorCompletionHandler)completion;

- (void)cancelTranslation;

+ (void)flushCache;

@end
