//
//  FGTranslator.m
//  Fargate
//
//  Created by George Polak on 1/14/13.
//
//

#import "FGTranslator.h"
#import "FGConstants.h"
#import "FGUtils.h"
#import "FGAPITranslateRequest.h"
#import "Fargate.h"
#import "NSString+Fargate.h"

@interface FGTranslator()
{
    AFJSONRequestOperation *_operation;
}

@property (nonatomic, copy) FGTranslatorCompletionHandler completionHandler;

@end


@implementation FGTranslator

@synthesize text = _text;
@synthesize source = _source;
@synthesize target = _target;

- (id)init
{
    self = [super init];
    if (self)
    {
        _state = 0;
        _target = [FGUtils filteredLanguageCodeFromCode:[Fargate sharedInstance].profile.translationLanguage];
    }
    
    return self;
}

- (void)dealloc
{
    FGDebug(@"translator dealloc called");
}

+ (NSCache *)translationCache
{
    static dispatch_once_t pred = 0;
    __strong static NSCache *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[NSCache alloc] init];
    });
    return _sharedObject;
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

- (void)translateText:(NSString *)text withSource:(NSString *)source completion:(FGTranslatorCompletionHandler)completion
{
    if (!text)
        return;
    
    if (!completion)
        return;
    
    if (_state == -1 || _state == 2)
        return;
    
    FGDebug(@"translator supplied params source:%@ target: %@", source, _target);
    
    NSCache *cache = [FGTranslator translationCache];
    NSDictionary *cached = [cache objectForKey:text];
    if (cached)
    {
        NSString *source = [cached objectForKey:@"src"];
        NSString *translated = [cached objectForKey:@"txt"];
        
        FGDebug(@"found cached translation: %@ (%@) for text: %@", translated, source, text);
        
        completion(nil, translated, source);
        _state = 2;
        return;
    }
    
    source = [FGUtils filteredLanguageCodeFromCode:source];
    if ([[source lowercaseString] isEqualToString:_target])
        source = nil;
    
    if ([self shouldGuessSourceWithText:text])
        source = nil;
    
    _state = source != nil ? 1 : 2;
    _text = text;
    
    if (!text || text.length == 0)
    {
        NSError *error = [FGUtils errorWithDomain:FG_ERROR_DOMAIN code:FGTranslatorErrorUnableToTranslate description:@"nil text"];
        completion(error, nil, nil);
    }
    
    FGDebug(@"translator calling with state: %i text:%@ source:%@ target: %@", _state, text, source, _target);
    
//    _retained_self = self;
    
    self.completionHandler = completion;
    
    [FGAPITranslateRequest translateMessage:text withSource:source target:_target provider:[Fargate sharedInstance].profile.translationProvider completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error) {
        
        if (error)
            [self handleError:error];
        else
            [self handleSuccessWithText:translatedMessage source:detectedSource];
        
    }];
}

- (void)handleError:(NSError *)error
{
    FGError(@"translator failed with error: %@", error);
    
    FGTranslatorError errorState;
    if (error.code == FGTranslationErrorBadRequest)
    {
        if (_state != 2)
        {
            _state = 2;
            
            [FGAPITranslateRequest translateMessage:_text withSource:nil target:_target provider:[Fargate sharedInstance].profile.translationProvider completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *theError) {
                if (error)
                    [self handleError:theError];
                else
                    [self handleSuccessWithText:translatedMessage source:detectedSource];
            }];
        }
        
        errorState = FGTranslatorErrorUnableToTranslate;
    }
    else
    {
        errorState = FGTranslatorErrorNetworkError;
    }
    
    NSError *fgError = [FGUtils errorWithDomain:FG_ERROR_DOMAIN code:errorState description:nil];
    if (self.completionHandler)
        self.completionHandler(fgError, nil, nil);
    self.completionHandler = nil;
//    _retained_self = nil;
}

- (void)handleSuccessWithText:(NSString *)translatedText source:(NSString *)source
{
    FGDebug(@"translator finished with text:%@ source:%@", translatedText, source);
    
    if (_state == 1)
    {
        _state = 2;
        
        if (![FGUtils isTranslated:translatedText sameAsOriginal:self.text])
        {
            FGDebug(@"translator succeeded with supplied source");
            
            [self cacheText:_text translated:translatedText source:source];
            
            if (self.completionHandler)
                self.completionHandler(nil, translatedText, source);
            self.completionHandler = nil;
//            _retained_self = nil;
        }
        else
        {
            FGDebug(@"translator will attempt to auto-detect source");
            
            // attempt to auto detect source
            [FGAPITranslateRequest translateMessage:_text withSource:nil target:_target provider:[Fargate sharedInstance].profile.translationProvider completion:^(NSString *translatedMessage, NSString *detectedSource, NSError *error) {
                if (error)
                    [self handleError:error];
                else
                    [self handleSuccessWithText:translatedMessage source:detectedSource];
            }];
        }
    }
    else if (_state == 2)
    {
        if (![FGUtils isTranslated:translatedText sameAsOriginal:self.text])
        {
            FGDebug(@"translator succeeded without a supplied source");
            
            [self cacheText:_text translated:translatedText source:source];
            
            if (self.completionHandler)
                self.completionHandler(nil, translatedText, source);
            self.completionHandler = nil;
        }
        else
        {
            if (FGIsDebugEnabled)
            {
                FGDebug(@"translator unable to translate with guessing a source");
                FGDebug(@"original>%@<", self.text);
                FGDebug(@"translated>%@<", translatedText);
            }
            
            // same, unable to translate
            NSError *fgError = [FGUtils errorWithDomain:FG_ERROR_DOMAIN code:FGTranslatorErrorSame description:nil];
            if (self.completionHandler)
                self.completionHandler(fgError, nil, nil);
            self.completionHandler = nil;
        }
        
//        _retained_self = nil;
    }
}

- (BOOL)shouldGuessSourceWithText:(NSString *)text
{
    return [text wordCount] >= 5 && [text wordCharacterCount] >= 25;
}

- (void)cancelTranslation
{
    [_operation cancel];
    _state = -1;
    self.completionHandler = nil;
    
//    _retained_self = nil;
}

@end
