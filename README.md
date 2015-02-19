![FGTranslator](fgtranslator_logo.png)

A simple iOS library for Google & Bing translation APIs.


## Quick Start (Google)

```objective-c
FGTranslator *translator = [[FGTranslator alloc] initWithGoogleAPIKey:@"your_google_key"];

[translator translateText:@"Bonjour!" 
               completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
{
	if (error)
    	NSLog(@"translation failed with error: %@", error);
	else
		NSLog(@"translated from %@: %@", sourceLanguage, translated);
}];
```

## Quick Start (Bing)

```objective-c
FGTranslator *translator =
	[[FGTranslator alloc] initWithBingAzureClientId:@"your_azure_client_id"
											 secret:@"your_azure_client_secret"];

[translator translateText:@"Bonjour!" 
               completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
{
	if (error)
    	NSLog(@"translation failed with error: %@", error);
	else
		NSLog(@"translated from %@: %@", sourceLanguage, translated);
}];
```

## Demo

1. Go to the FGTranslatorDemo directory.
2. Open the `.xcworkspace` (**not the `.xcodeproj`!**) file.
3. Run the app.

## Adding FGTranslator to Your Project

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like FGTranslator in your projects. See the ["Getting Started"](https://github.com/gpolak/FGTranslator/wiki/Installing-FGTranslator-via-CocoaPods) guide for more information.

```ruby
platform :ios, '6.0'
pod "FGTranslator"
```

### Source Files

Alternatively you can directly add the *FGTranslator* folder to your project. FGTranslator uses [AFNetworking](https://github.com/AFNetworking/AFNetworking) - your project needs this for it to work if you include it this way. CocoaPods install manages this dependency for you.


## Register With Google or Bing

To use this library you need a valid Google or Bing (Azure) developer account.

Google and Bing Translate are both paid services, but Bing offers a free tier. Google's translation quality and language selection is generally better. Pick what works best for you.

- **Google**
  1. https://developers.google.com/translate/v2/getting_started
- **Bing** 
  1. Subscribe to the Microsoft Translator API on [Azure Marketplace](http://go.microsoft.com/?linkid=9782667). Basic subscriptions, up to 2 million characters a month, are free.
  2. To register your application with Azure DataMarket, visit https://datamarket.azure.com/developer/applications/ using the LiveID credentials from step 1, and click on “Register”. In the “Register your application” dialog box, you can define your own Client ID and Name. The redirect URI is not used for the Microsoft Translator API. However, the redirect URI field is a mandatory field, and you must provide a URI to obtain the access code (just use *http://example.com* to make it happy). 
Take a note of the **client ID** and the **client secret** value.
  3. Make sure you have an [Active Subscription](https://datamarket.azure.com/dataset/bing/microsofttranslator) data plan. The first tier (2M characters) is free.


## Usage

### Initialize with Google...

```objective-c
FGTranslator *translator =
	[[FGTranslator alloc] initWithGoogleAPIKey:@"your_google_key"];
```

### ...or Bing

```objective-c
FGTranslator *translator =
	[[FGTranslator alloc] initWithBingAzureClientId:@"your_azure_client_id"
                                             secret:@"your_azure_client_secret"];
```

### Translate
```objective-c
[translator translateText:@"Bonjour!" completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
{
	if (error)
	{
    	NSLog(@"failed with error: %@", error);
	}
	else
	{
    	NSString *fromLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:sourceLanguage];
		NSLog(@"translated from %@: %@", fromLanguage, translated);
	}
}];
```

> Note that translations are one-shot operations. You need to instantiate a new `FGTranslator` object for each translation.


### Detect Language

Detects the language and returns its ISO language code as the `detectedSource` parameter.

If initialized with Google, the completion handler also returns a float between 0 and 1 indicating the confidence of the match, with 1 being the highest confidence. This is not supported with Bing translate and will always returns `FGTranslatorUnknownConfidence`.

```objective-c
[translator detectLanguage:@"Bonjour"
                completion:^(NSError *error, NSString *detectedSource, float confidence)
{
   if (error)
   {
       NSLog(@"failed with error: %@", error);
   }
   else
   {
       NSString *language = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:detectedSource];       
       NSString *confidenceMessage = confidence == FGTranslatorUnknownConfidence
           ? @"unknown"
           : [NSString stringWithFormat:@"%.1f%%", confidence * 100];
           
       NSLog(@"detected %@ with %@ confidence", language, confidenceMessage);
   }
}];
```

### Get a List of Supported Languages

Google and Bing Translate support different languages. You can get a list of supported ISO language codes with the following function:

```objective-c
[translator supportedLanguages:^(NSError *error, NSArray *languageCodes)
{
   if (error)
       NSLog(@"failed with error: %@", error);
   else
       NSLog(@"supported languages:%@", languageCodes);
}];
```

## Fancy Stuff

### Specify Source or Target Language

The basic translation function makes a guess at the source language and specifies the target language based on the user's phone settings:
```objective-c
- (void)translateText:(NSString *)text
           completion:(NSError *error, NSString *translated, NSString *sourceLanguage)completion;
```

You can specify the source and/or the target languages if desired:
```objective-c
- (void)translateText:(NSString *)text
           withSource:(NSString *)source
               target:(NSString *)target
           completion:(NSError *error, NSString *translated, NSString *sourceLanguage)completion;
```

### Disable Smart Guessing

Usually you don't know the source language to translate from. Going by user's iPhone locale or keyboard language settings seems like the obvious answer, but it is unreliable: there's nothing stopping you from typing *Hola amigo!* with an English keyboard. This is common, especially with international users.

For this reason FGTranslator will ignore the passed-in `source` parameter in the above function, if it determines a good guess can be made. Typically this means that the `text` parameter is complex and long enough for the engine to reliably determine the language. Short string snippets will typically respect the passed-in `source` parameter, if any.

To force FGTranslator to always respect the `source` parameter, use the following property:
```objective-c
translator.preferSourceGuess = NO;
```
> Note: Unless you definitely know the source language, I recommend leaving smart guessing on **AND** passing the source parameter if available as a hint to the language detector.


### User Throttles *(Google Only)*

For Google Translate, you can throttle usage on a per-user/device basis by setting a specific user identifier property in the `FGTranslator` instance. See the specific [Google documentation](https://developers.google.com/console/help/new/#cappingusage) for more information.

```objective-c
@property (nonatomic) NSString *quotaUser;
```
	
### Cancel a Translation In Progress
```objective-c
- (void)cancel;
```
### Flush Cache

Translations are cached to prevent unnecessary network calls (and Google/Bing API charges). You can flush the cache if needed:
```objective-c
+ (void)flushCache;
```
	
### Flush Credentials *(Bing Only)*

Bing Translate uses token-based authentication. The first call you make retrieves a token based on the passed-in client ID and secret and caches it for future use. The lifetime of the token is 15 minutes, after which it expires and a new one will be fetched. To force the token expiry, call the following function:
```objective-c
+ (void)flushCredentials;
```
	

## Attributions

FGTranslator uses the following projects:

- [XMLDictionary](https://github.com/nicklockwood/XMLDictionary)
- [AFNetworking](https://github.com/AFNetworking/AFNetworking)
	- I also cribbed some parts of the README. Great job explaining CocoaPods usage guys!
	
## License

FGTranslator is available under the MIT license. See the LICENSE file for more info.


## Misc

### FG?

FGTranslator comes from my [Fargate](http://fargate.net) app.

### Fish Logo?

[Fish logo.](http://en.wikipedia.org/wiki/Babel_fish_\(The_Hitchhiker%27s_Guide_to_the_Galaxy\)#Babel_fish)
