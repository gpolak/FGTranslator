//
//  FGTranslator.h
//  Fargate
//
//  Created by George Polak on 1/14/13.
//
//

#import <Foundation/Foundation.h>

typedef NSInteger FGTranslatorError;
typedef NSInteger FGTranslationState;

enum FGTranslationState
{
    FGTranslationStateNone = 0,
    FGTranslationStateTranslated = 1,
    FGTranslationStateSame = 2,
    FGTranslationStateUnavailable = 3
};

enum FGTranslatorError
{
    FGTranslatorErrorUnableToTranslate = 0,
    FGTranslatorErrorNetworkError = 1,
    FGTranslatorErrorSame = 2
};

@interface FGTranslator : NSObject
{
    /*
     * -1 = cancelled
     * 0 = initial
     * 1 = first try
     * 2 = finished
     */
    // TODO: is this needed?
    NSInteger _state;
    
    __strong FGTranslator *_retained_self;
}

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
