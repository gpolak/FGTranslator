//
//  FGTranslator.m
//  Fargate
//
//  Created by George Polak on 1/14/13.
//
//

#import "FGTranslator.h"
#import "FGTranslateRequest.h"
#import "NSString+FGTranslator.h"
#import <AFNetworking.h>
#import <TMCache.h>

typedef NSInteger FGTranslatorState;

enum FGTranslatorState
{
    FGTranslatorStateInitial = 0,
    FGTranslatorStateInProgress = 1,
    FGTranslatorStateCompleted = 2
};

float const FGTranslatorUnknownConfidence = -1;

@interface FGTranslator()
{
}

@property (nonatomic) NSString *googleAPIKey;
@property (nonatomic) NSString *azureClientId;
@property (nonatomic) NSString *azureClientSecret;

@property (nonatomic) FGTranslatorState translatorState;

@property (nonatomic) AFHTTPRequestOperation *operation;
@property (nonatomic, copy) FGTranslatorCompletionHandler completionHandler;

@end


@implementation FGTranslator

- (id)initWithGoogleAPIKey:(NSString *)key
{
    self = [self initGeneric];
    if (self)
    {
        self.googleAPIKey = key;
    }
    
    return self;
}

- (id)initWithBingAzureClientId:(NSString *)clientId secret:(NSString *)secret
{
    self = [self initGeneric];
    if (self)
    {
        self.azureClientId = clientId;
        self.azureClientSecret = secret;
    }
    
    return self;
}

- (id)initGeneric
{
    self = [super init];
    if (self)
    {
        self.preferSourceGuess = YES;
        self.translatorState = FGTranslatorStateInitial;
        
        // limit translation cache to 5 MB
        TMCache *cache = [TMCache sharedCache];
        cache.diskCache.byteLimit = 5000000;
    }
    
    return self;
}

+ (void)flushCredentials
{
    [FGTranslateRequest flushCredentials];
}

+ (void)flushCache
{
    [[TMCache sharedCache] removeAllObjects];
}

- (void)cacheText:(NSString *)text translated:(NSString *)translated source:(NSString *)source
{
    if (!text || !translated)
        return;
    
    NSMutableDictionary *cached = [NSMutableDictionary new];
    [cached setObject:translated forKey:@"txt"];
    if (source)
        [cached setObject:source forKey:@"src"];
    
    [[TMCache sharedCache] setObject:cached forKey:text];
}

- (void)translateText:(NSString *)text
           completion:(FGTranslatorCompletionHandler)completion
{
    [self translateText:text withSource:nil target:nil completion:completion];
}

- (void)translateText:(NSString *)text
           withSource:(NSString *)source
               target:(NSString *)target
           completion:(FGTranslatorCompletionHandler)completion;
{
    if (!completion || !text || text.length == 0)
        return;
    
    if (self.googleAPIKey.length == 0 && (self.azureClientId.length == 0 || self.azureClientSecret.length == 0))
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorMissingCredentials
                                 description:@"missing Google or Bing credentials"];
        completion(error, nil, nil);
        return;
    }
    
    if (self.translatorState == FGTranslatorStateInProgress)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorTranslationInProgress description:@"translation already in progress"];
        completion(error, nil, nil);
        return;
    }
    else if (self.translatorState == FGTranslatorStateCompleted)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorAlreadyTranslated description:@"translation already completed"];
        completion(error, nil, nil);
        return;
    }
    else
    {
        self.translatorState = FGTranslatorStateInProgress;
    }
    
    // check cache for existing translation
    NSDictionary *cached = [[TMCache sharedCache] objectForKey:text];
    if (cached)
    {
        NSString *cachedSource = [cached objectForKey:@"src"];
        NSString *cachedTranslation = [cached objectForKey:@"txt"];
        
        NSLog(@"FGTranslator: returning cached translation");
        
        completion(nil, cachedTranslation, cachedSource);
        return;
    }
    
    source = [self filteredLanguageCodeFromCode:source];
    if (!target)
        target = [self filteredLanguageCodeFromCode:[[NSLocale preferredLanguages] objectAtIndex:0]];
    
    if ([[source lowercaseString] isEqualToString:target])
        source = nil;
    
    if (self.preferSourceGuess && [self shouldGuessSourceWithText:text])
        source = nil;
    
    self.completionHandler = completion;
    
    if (self.googleAPIKey)
    {
        self.operation = [FGTranslateRequest googleTranslateMessage:text
                                                         withSource:source
                                                             target:target
                                                                key:self.googleAPIKey
                                                          quotaUser:self.quotaUser
                                                         completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error)
        {
            if (error)
                [self handleError:error];
            else
                [self handleSuccessWithOriginal:text translatedMessage:translatedMessage detectedSource:detectedSource];
            
            self.translatorState = FGTranslatorStateCompleted;
        }];
    }
    else if (self.azureClientId && self.azureClientSecret)
    {
        self.operation = [FGTranslateRequest bingTranslateMessage:text
                                                       withSource:source
                                                           target:target
                                                         clientId:self.azureClientId
                                                     clientSecret:self.azureClientSecret
                                                       completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error)
        {
            if (error)
                [self handleError:error];
            else
                [self handleSuccessWithOriginal:text translatedMessage:translatedMessage detectedSource:detectedSource];
            
            self.translatorState = FGTranslatorStateCompleted;
        }];
    }
    else
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorMissingCredentials
                                 description:@"missing Google or Bing credentials"];
        completion(error, nil, nil);
        
        self.translatorState = FGTranslatorStateCompleted;
    }
}

- (void)detectLanguage:(NSString *)text
            completion:(void (^)(NSError *error, NSString *detectedSource, float confidence))completion
{
    if (!completion || !text || text.length == 0)
        return;
    
    if (self.googleAPIKey.length == 0 && (self.azureClientId.length == 0 || self.azureClientSecret.length == 0))
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorMissingCredentials
                                 description:@"missing Google or Bing credentials"];
        completion(error, nil, 0);
        return;
    }
    
    if (self.translatorState == FGTranslatorStateInProgress)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorTranslationInProgress description:@"detection already in progress"];
        completion(error, nil, 0);
        return;
    }
    else if (self.translatorState == FGTranslatorStateCompleted)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorAlreadyTranslated description:@"detection already completed"];
        completion(error, nil, 0);
        return;
    }
    else
    {
        self.translatorState = FGTranslatorStateInProgress;
    }
    
    if (self.googleAPIKey)
    {
        self.operation = [FGTranslateRequest googleDetectLanguage:text
                                                              key:self.googleAPIKey
                                                        quotaUser:self.quotaUser
                                                       completion:^(NSString *detectedSource, float confidence, NSError *error)
                          {
                              if (error)
                              {
                                  FGTranslatorError errorState = error.code == FGTranslationErrorBadRequest ? FGTranslatorErrorUnableToTranslate : FGTranslatorErrorNetworkError;
                                  
                                  NSError *fgError = [self errorWithCode:errorState description:nil];
                                  if (completion)
                                      completion(fgError, nil, 0);
                              }
                              else
                              {
                                  completion(nil, detectedSource, confidence);
                              }
                              
                              self.translatorState = FGTranslatorStateCompleted;
                          }];
    }
    else if (self.azureClientId && self.azureClientSecret)
    {
        self.operation = [FGTranslateRequest bingDetectLanguage:text
                                                       clientId:self.azureClientId
                                                   clientSecret:self.azureClientSecret
                                                     completion:^(NSString *detectedLanguage, float confidence, NSError *error)
        {
            if (error)
            {
                FGTranslatorError errorState = error.code == FGTranslationErrorBadRequest ? FGTranslatorErrorUnableToTranslate : FGTranslatorErrorNetworkError;
                
                NSError *fgError = [self errorWithCode:errorState description:nil];
                if (completion)
                    completion(fgError, nil, 0);
            }
            else
            {
                completion(nil, detectedLanguage, confidence);
            }
            
            self.translatorState = FGTranslatorStateCompleted;
        }];
    }
    else
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorMissingCredentials
                                 description:@"missing Google or Bing credentials"];
        completion(error, nil, 0);
        
        self.translatorState = FGTranslatorStateCompleted;
    }
}

- (void)supportedLanguages:(void (^)(NSError *error, NSArray *languageCodes))completion
{
    if (!completion)
        return;
    
    if (self.googleAPIKey.length == 0 && (self.azureClientId.length == 0 || self.azureClientSecret.length == 0))
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorMissingCredentials
                                 description:@"missing Google or Bing credentials"];
        completion(error, nil);
        return;
    }
    
    if (self.translatorState == FGTranslatorStateInProgress)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorTranslationInProgress description:@"detection already in progress"];
        completion(error, nil);
        return;
    }
    else if (self.translatorState == FGTranslatorStateCompleted)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorAlreadyTranslated description:@"detection already completed"];
        completion(error, nil);
        return;
    }
    else
    {
        self.translatorState = FGTranslatorStateInProgress;
    }
    
    if (self.googleAPIKey)
    {
        self.operation = [FGTranslateRequest googleSupportedLanguagesWithKey:self.googleAPIKey
                                                                   quotaUser:self.quotaUser
                                                                  completion:^(NSArray *languageCodes, NSError *error)
        {
            if (error)
            {
                FGTranslatorError errorState = error.code == FGTranslationErrorBadRequest ? FGTranslatorErrorUnableToTranslate : FGTranslatorErrorNetworkError;
                
                NSError *fgError = [self errorWithCode:errorState description:nil];
                if (completion)
                    completion(fgError, nil);
            }
            else
            {
                completion(nil, languageCodes);
            }
            
            self.translatorState = FGTranslatorStateCompleted;
        }];
    }
    else if (self.azureClientId && self.azureClientSecret)
    {
        self.operation = [FGTranslateRequest bingSupportedLanguagesWithClienId:self.azureClientId
                                                                  clientSecret:self.azureClientSecret
                                                                    completion:^(NSArray *languageCodes, NSError *error)
        {
            if (error)
            {
                FGTranslatorError errorState = error.code == FGTranslationErrorBadRequest ? FGTranslatorErrorUnableToTranslate : FGTranslatorErrorNetworkError;
                  
                NSError *fgError = [self errorWithCode:errorState description:nil];
                if (completion)
                    completion(fgError, nil);
            }
            else
            {
                completion(nil, languageCodes);
            }
              
            self.translatorState = FGTranslatorStateCompleted;
        }];
    }
    else
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorMissingCredentials
                                 description:@"missing Google or Bing credentials"];
        completion(error, nil);
        
        self.translatorState = FGTranslatorStateCompleted;
    }
}

- (void)handleError:(NSError *)error
{
    FGTranslatorError errorState = error.code == FGTranslationErrorBadRequest ? FGTranslatorErrorUnableToTranslate : FGTranslatorErrorNetworkError;
    
    NSError *fgError = [self errorWithCode:errorState description:nil];
    if (self.completionHandler)
        self.completionHandler(fgError, nil, nil);
}

- (void)handleSuccessWithOriginal:(NSString *)original
                translatedMessage:(NSString *)translatedMessage
                   detectedSource:(NSString *)detectedSource
{
    if ([self isTranslated:translatedMessage sameAsOriginal:original])
    {
        NSError *fgError = [self errorWithCode:FGTranslatorErrorUnableToTranslate description:@"unable to translate"];
        if (self.completionHandler)
            self.completionHandler(fgError, nil, nil);
    }
    else
    {
        self.completionHandler(nil, translatedMessage, detectedSource);
        [self cacheText:original translated:translatedMessage source:detectedSource];
    }
}

- (void)cancel
{
    self.completionHandler = nil;
    [self.operation cancel];
}


#pragma mark - Utils

- (BOOL)shouldGuessSourceWithText:(NSString *)text
{
    return [text wordCount] >= 5 && [text wordCharacterCount] >= 25;
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description
{
    NSDictionary *userInfo = nil;
    if (description)
        userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:code userInfo:userInfo];
}

// NOT to be used for general string comparison, just to eliminate translator weirdness
- (BOOL)isTranslated:(NSString *)translated sameAsOriginal:(NSString *)original
{
    if (!translated || !original)
        return NO;
    
    NSString *t = [translated stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *o = [original stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return [t caseInsensitiveCompare:o] == NSOrderedSame;
}

// massage languge code to make Google Translate happy
- (NSString *)filteredLanguageCodeFromCode:(NSString *)code
{
    if (!code || code.length <= 3)
        return code;
    
    if ([code isEqualToString:@"zh-Hant"] || [code isEqualToString:@"zh-TW"])
        return @"zh-TW";
    else if ([code hasSuffix:@"input"])
        // use phone's default language if crazy (keyboard) inputs are detected
        return [[NSLocale preferredLanguages] objectAtIndex:0];
    else
        // trim stuff like en-GB to just en which Google Translate understands
        return [code substringToIndex:2];
}

@end
