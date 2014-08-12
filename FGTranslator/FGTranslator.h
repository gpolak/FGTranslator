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
    NSInteger _state;
    NSString *_text;
    NSString *_source;
    NSString *_target;
    
    __strong FGTranslator *_retained_self;
}

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *source;
@property (nonatomic, readonly) NSString *target;

typedef void (^FGTranslatorCompletionHandler)(NSError *error, NSString *translated, NSString *source);

- (void)translateText:(NSString *)text withSource:(NSString *)source completion:(FGTranslatorCompletionHandler)completion;
- (void)cancelTranslation;

+ (void)flushCache;

@end
