//
//  FGAzureToken.h
//  Fargate
//
//  Created by George Polak on 10/9/13.
//
//

#import <Foundation/Foundation.h>

@interface FGAzureToken : NSObject

@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSDate *expiry;


- (id)initWithToken:(NSString *)token expiry:(NSDate *)expiry;

- (BOOL)isValid;

@end
