# FGTranslator

A simple iOS library for Google & Bing translation APIs.


## Register with Google or Bing

To use this library you need a valid Google or Bing (Azure) developer account.

Google and Bing Translate are both paid services, but Bing offers a free tier. Google's translation quality and language selection is generally better. Pick what works best for you.

**Google:** https://developers.google.com/translate/v2/getting_started

**Bing:** http://www.microsoft.com/web/post/using-the-free-bing-translation-apis


## Usage

### Initialize with Google...

```
FGTranslator *translator = [[FGTranslator alloc] initWithGoogleAPIKey:@"your_google_key"];
```

### ...or Bing

```
FGTranslator *translator = [[FGTranslator alloc] initWithBingAzureClientId:@"your_azure_client_id"
                                                                    secret:@"your_azure_client_secret"];
```

## Attributions

* XMLDictionary
* AFNetworking

## Notes

- Bing cannot detect language