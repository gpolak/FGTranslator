![FGTranslator](fgtranslator_logo.png)

A simple iOS library for Google & Bing translation APIs.


## Synopsis

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

## Adding FGTranslator to Your Project

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like FGTranslator in your projects. See the ["Getting Started"](https://github.com/gpolak/FGTranslator/wiki/Installing-FGTranslator-via-CocoaPods) guide for more information.

```ruby
platform :ios, '6.0'
pod "FGTranslator"
```

### Source Files

Alternatively you can directly add the *FGTranslator* folder to your project. FGTranslator uses [AFNetworking](https://github.com/AFNetworking/AFNetworking) - your project needs this for it to work if you include it this way.


## Register With Google or Bing

To use this library you need a valid Google or Bing (Azure) developer account.

Google and Bing Translate are both paid services, but Bing offers a free tier. Google's translation quality and language selection is generally better. Pick what works best for you.

- **Google:** https://developers.google.com/translate/v2/getting_started
- **Bing:** http://www.microsoft.com/web/post/using-the-free-bing-translation-apis


## Running the Demo

1. Go to the FGTranslatorDemo directory.
2. Open the `.xcworkspace` (**not the `.xcodeproj`!**) file.
2. Navigate to the `ViewController.m` file.
	- Find the following line and add your Google API key: `static NSString *GOOGLE_API_KEY = nil;`
	- Uncomment the relevant code below to use Bing Translate. It should be obvious.
4. Run the app in the Simulator.

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
    	NSLog(@"translation failed with error: %@", error);
	}
	else
	{
    	NSString *fromLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:sourceLanguage];
		NSLog(@"translated from %@: %@", fromLanguage, translated);
	}
}];
```

> Note that translations are one-shot operations. You need to instantiate a new `FGTranslator` object for each translation.

## Fancy Stuff

### Specify Source or Target Language

The basic translation function makes a guess at the source language and specifies the target language based on the user's phone settings.
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
	
### Cancel Translation
```objective-c
- (void)cancel;
```
### Flush Cache

Translations are cached to prevent unnecessary network calls (and Google/Bing API charges). You can flush the cache if needed:
```objective-c
+ (void)flushCache;
```
> Note: The translation cache is implemented as a simple NSCache and hence will be cleared periodically by the OS. 
	
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


## Misc

### FG?

FGTranslator comes from my [Fargate](http://fargate.net) app.

### Fish Logo?

[Fish logo.](http://en.wikipedia.org/wiki/Babel_fish_\(The_Hitchhiker%27s_Guide_to_the_Galaxy\)#Babel_fish)
