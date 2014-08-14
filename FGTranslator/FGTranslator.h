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
    FGTranslatorErrorMissingCredentials = 5
};

@interface FGTranslator : NSObject
{
}

@property (nonatomic) BOOL preferSourceGuess;

@property (nonatomic, readonly) NSString *googleAPIKey;
@property (nonatomic, readonly) NSString *azureClientId;
@property (nonatomic, readonly) NSString *azureClientSecret;

typedef void (^FGTranslatorCompletionHandler)(NSError *error, NSString *translated, NSString *sourceLanguage);

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
+ (void)flushCredentials;

@end
