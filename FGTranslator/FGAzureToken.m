//
//  FGAzureToken.m
//  Fargate
//
//  Created by George Polak on 10/9/13.
//
//

#import "FGAzureToken.h"

@interface FGAzureToken ()

@property (nonatomic) NSString *token;
@property (nonatomic) NSDate *expiry;

@end


@implementation FGAzureToken

- (id)initWithToken:(NSString *)token expiry:(NSDate *)expiry
{
    self = [super init];
    if (self)
    {
        self.token = token;
        self.expiry = expiry;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"token:%@ expiry:%@", self.token, self.expiry];
}

- (BOOL)isValid
{
    if (!self.token || !self.expiry)
        return NO;
    
    return [self.expiry timeIntervalSinceNow] > 0;
}


@end
