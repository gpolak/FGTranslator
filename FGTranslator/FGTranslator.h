//
//  FGTranslator.h
//  Fargate
//
//  Created by George Polak on 1/14/13.
//
//

#import <Foundation/Foundation.h>

/**
 * Error domain for FGTranslator errors.
 */ 
typedef NSInteger FGTranslatorError;

/**
 * FGTranslator specific error
 */
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

/**
 * Set to 'true' to enable source guessing, false to always respect the 'source' parameter in translate functions. Default true.
 */
@property (nonatomic) BOOL preferSourceGuess;

/**
 * Google API key, if any.
 */
@property (nonatomic, readonly) NSString *googleAPIKey;
/**
 * Bing Azure client ID, if any.
 */
@property (nonatomic, readonly) NSString *azureClientId;
/**
 * Bing Azure client secret, if any.
 */
@property (nonatomic, readonly) NSString *azureClientSecret;

typedef void (^FGTranslatorCompletionHandler)(NSError *error, NSString *translated, NSString *sourceLanguage);

/**
 * Initialize translator with Google Translate.
 
 * @param key Google API key
 
 * @return FGTranslator instance.
 */
- (id)initWithGoogleAPIKey:(NSString *)key;

/**
 * Initialize translator with Bing Translate.
 
 * @param clientId Azure client ID
 * @param clientSecret Azure client secret
 
 * @return FGTranslator instance.
 */
- (id)initWithBingAzureClientId:(NSString *)clientId secret:(NSString *)secret;

/**
 * Translate text.
 
 * The translator will attempt to guess the source language, and user the current iPhone locale for the target language.
 
 * @param text Text to translate.
 * @param completion Completion handler.
 */
- (void)translateText:(NSString *)text
           completion:(FGTranslatorCompletionHandler)completion;
/**
 * Translate text.
 
 * @param text Text to translate.
 * @param source ISO language code of the source text. Leave 'nil' to guess.
 * @param target ISO language code of the desired language output. Leave 'nil' to use iPhone's current locale.
 * @param completion Completion handler.
 
 * @discussion If the `preferSourceGuess` property is set to TRUE (default), the translator will ignore the passed-in `source` 
 * parameter (if any) if it determines a reliable guess can be made.
 */
- (void)translateText:(NSString *)text
           withSource:(NSString *)source
               target:(NSString *)target
           completion:(FGTranslatorCompletionHandler)completion;

/**
 * Cancels the current translation.
 */
- (void)cancelTranslation;

/**
 * Flushes the translation cache.
 
 * Previous translation results are cached (on a per-target-language basis). Call this function to clear the cache.
 */
+ (void)flushCache;

/**
 Flush Azure credentials.
 
 This deletes the existing token, if any.
 */
+ (void)flushCredentials;

@end
