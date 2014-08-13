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

@interface FGTranslator()
{
}

@property (nonatomic) NSString *googleAPIKey;
@property (nonatomic) NSString *azureClientId;
@property (nonatomic) NSString *azureClientSecret;

@property (nonatomic, copy) FGTranslatorCompletionHandler completionHandler;

@end


@implementation FGTranslator

- (id)initWithGoogleAPIKey:(NSString *)key
{
    self = [super init];
    if (self)
    {
        _state = FGTranslationStateNone;
        
        self.googleAPIKey = key;
    }
    
    return self;
}

- (id)initWithBingAzureClientId:(NSString *)clientId secret:(NSString *)secret
{
    self = [super init];
    if (self)
    {
        _state = FGTranslationStateNone;
        
        self.azureClientId = clientId;
        self.azureClientSecret = secret;
    }
    
    return self;
}

// TODO: remove this
- (void)dealloc
{
    NSLog(@"FGTranslator dealloc called");
}

+ (NSCache *)translationCache
{
    static dispatch_once_t pred = 0;
    __strong static NSCache *translationCache = nil;
    dispatch_once(&pred, ^{
        translationCache = [[NSCache alloc] init];
    });
    return translationCache;
}

+ (void)flushCache
{
    [[FGTranslator translationCache] removeAllObjects];
}

- (void)cacheText:(NSString *)text translated:(NSString *)translated source:(NSString *)source
{
    if (!text || !translated)
        return;
    
    NSMutableDictionary *cached = [NSMutableDictionary new];
    [cached setObject:translated forKey:@"txt"];
    if (source)
        [cached setObject:source forKey:@"src"];
    
    [[FGTranslator translationCache] setObject:cached forKey:text];
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
    if (!text)
        return;
    
    if (!completion)
        return;
    
    if (_state == -1 || _state == 2)
        return;
    
    // TODO: remove this
    NSLog(@"translator supplied params source:%@ target: %@", source, target);
    
    NSCache *cache = [FGTranslator translationCache];
    NSDictionary *cached = [cache objectForKey:text];
    if (cached)
    {
        NSString *cachedSource = [cached objectForKey:@"src"];
        NSString *cachedTranslation = [cached objectForKey:@"txt"];
        
        NSLog(@"found cached translation: %@ (%@) for text: %@", cachedTranslation, cachedSource, text);
        
        completion(nil, cachedTranslation, cachedSource);
        _state = 2;
        return;
    }
    
    source = [self filteredLanguageCodeFromCode:source];
    if (!target)
        target = [self filteredLanguageCodeFromCode:[[NSLocale preferredLanguages] objectAtIndex:0]];
    
    if ([[source lowercaseString] isEqualToString:target])
        source = nil;
    
    if ([self shouldGuessSourceWithText:text])
        source = nil;
    
    _state = source != nil ? 1 : 2;    
    
    if (!text || text.length == 0)
    {
        NSError *error = [self errorWithCode:FGTranslatorErrorUnableToTranslate description:@"nil text"];
        completion(error, nil, nil);
    }
    
    // TODO: remove
    NSLog(@"translator calling with state: %i text:%@ source:%@ target: %@", _state, text, source, target);
    
//    _retained_self = self;
    
    self.completionHandler = completion;
    
    [FGTranslateRequest googleTranslateMessage:text
                                    withSource:source
                                        target:target
                                           key:self.googleAPIKey
                                    completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error)
    {
        // TODO: handle properly
        if (error)
        {
            NSLog(@"error: %@", error);
        }
        else
        {
            NSLog(@"SUCC: %@ (%@)", translatedMessage, detectedSource);
        }
    }];
    
//    [FGAPITranslateRequest translateMessage:text withSource:source target:_target provider:[Fargate sharedInstance].profile.translationProvider completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error) {
//        
//        if (error)
//            [self handleError:error];
//        else
//            [self handleSuccessWithText:translatedMessage source:detectedSource];
//        
//    }];
}

- (void)handleError:(NSError *)error
{
//    FGError(@"translator failed with error: %@", error);
//    
//    FGTranslatorError errorState;
//    if (error.code == FGTranslationErrorBadRequest)
//    {
//        if (_state != 2)
//        {
//            _state = 2;
//            
////            [FGAPITranslateRequest translateMessage:_text withSource:nil target:_target provider:[Fargate sharedInstance].profile.translationProvider completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *theError) {
////                if (error)
////                    [self handleError:theError];
////                else
////                    [self handleSuccessWithText:translatedMessage source:detectedSource];
////            }];
//        }
//        
//        errorState = FGTranslatorErrorUnableToTranslate;
//    }
//    else
//    {
//        errorState = FGTranslatorErrorNetworkError;
//    }
//    
////    NSError *fgError = [FGUtils errorWithDomain:FG_ERROR_DOMAIN code:errorState description:nil];
////    if (self.completionHandler)
////        self.completionHandler(fgError, nil, nil);
////    self.completionHandler = nil;
////    _retained_self = nil;
}

- (void)handleSuccessWithText:(NSString *)translatedText source:(NSString *)source
{
//    FGDebug(@"translator finished with text:%@ source:%@", translatedText, source);
//    
//    if (_state == 1)
//    {
//        _state = 2;
//        
//        if (![FGUtils isTranslated:translatedText sameAsOriginal:self.text])
//        {
//            FGDebug(@"translator succeeded with supplied source");
//            
//            [self cacheText:_text translated:translatedText source:source];
//            
//            if (self.completionHandler)
//                self.completionHandler(nil, translatedText, source);
//            self.completionHandler = nil;
////            _retained_self = nil;
//        }
//        else
//        {
//            FGDebug(@"translator will attempt to auto-detect source");
//            
//            // attempt to auto detect source
//            [FGAPITranslateRequest translateMessage:_text withSource:nil target:_target provider:[Fargate sharedInstance].profile.translationProvider completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error) {
//                if (error)
//                    [self handleError:error];
//                else
//                    [self handleSuccessWithText:translatedMessage source:detectedSource];
//            }];
//        }
//    }
//    else if (_state == 2)
//    {
//        if (![FGUtils isTranslated:translatedText sameAsOriginal:self.text])
//        {
//            FGDebug(@"translator succeeded without a supplied source");
//            
//            [self cacheText:_text translated:translatedText source:source];
//            
//            if (self.completionHandler)
//                self.completionHandler(nil, translatedText, source);
//            self.completionHandler = nil;
//        }
//        else
//        {
//            if (FGIsDebugEnabled)
//            {
//                FGDebug(@"translator unable to translate with guessing a source");
//                FGDebug(@"original>%@<", self.text);
//                FGDebug(@"translated>%@<", translatedText);
//            }
//            
//            // same, unable to translate
//            NSError *fgError = [FGUtils errorWithDomain:FG_ERROR_DOMAIN code:FGTranslatorErrorSame description:nil];
//            if (self.completionHandler)
//                self.completionHandler(fgError, nil, nil);
//            self.completionHandler = nil;
//        }
//        
////        _retained_self = nil;
//    }
}

- (BOOL)shouldGuessSourceWithText:(NSString *)text
{
    return [text wordCount] >= 5 && [text wordCharacterCount] >= 25;
}

- (void)cancelTranslation
{
//    [_operation cancel];
    _state = -1;
    self.completionHandler = nil;
    
//    _retained_self = nil;
}

#pragma mark - Utils

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description
{
    NSDictionary *userInfo = nil;
    if (description)
        userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:FG_TRANSLATOR_ERROR_DOMAIN code:code userInfo:userInfo];
}

// massage to make Google Translate happy
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
