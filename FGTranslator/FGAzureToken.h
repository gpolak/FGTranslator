//
//  FGAzureToken.h
//  Fargate
//
//  Created by George Polak on 10/9/13.
//
//

#import <Foundation/Foundation.h>

@interface FGAzureToken : NSObject

/**
 * The token itself.
 */
@property (nonatomic, readonly) NSString *token;
/**
 * Token expiry
 */
@property (nonatomic, readonly) NSDate *expiry;


/**
 Initializes an Azure token.
 
 @params
 token: token
 expire: token expiry
 
 @returns
 Token instance.
 */
- (id)initWithToken:(NSString *)token expiry:(NSDate *)expiry;

/**
 Determines token validity based on expiration date.
 @returns
 TRUE if token is valid, FALSE otherwise.
 */
- (BOOL)isValid;

@end
