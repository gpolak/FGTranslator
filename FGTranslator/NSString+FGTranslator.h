//
//  NSString+FGTranslator.h
//  FGTranslatorDemo
//
//  Created by George Polak on 8/12/14.
//  Copyright (c) 2014 George Polak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FGTranslator)

/** 
 * @return Number of words in the string.
 */
- (NSUInteger)wordCount;

/** 
 * @return Number of word-characters in the string. Ignoring whitespace, etc.
 */
- (NSUInteger)wordCharacterCount;

/** 
 * URL encodes string. Does away with some of the omissions from the default NSString encoding function.
 
 * @param original String to encode.
 
 * @return Encoded string.
 */
+ (NSString *)urlEncodedStringFromString:(NSString *)original;

@end
