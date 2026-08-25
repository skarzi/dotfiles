#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <math.h>

// Declared locally so we can message CoreBrightness without linking it.
@protocol KeyboardBrightnessClient
- (NSArray<NSNumber *> *)copyKeyboardBacklightIDs;
- (BOOL)isKeyboardBuiltIn:(unsigned long long)keyboardID;
- (float)brightnessForKeyboard:(unsigned long long)keyboardID;
- (BOOL)setBrightness:(float)brightness
          forKeyboard:(unsigned long long)keyboardID;
- (BOOL)enableAutoBrightness:(BOOL)enable
                 forKeyboard:(unsigned long long)keyboardID;
@end

static NSString *const kDyldHint =
    @"Re-discover with:\n"
    @"  dyld_info -exports /System/Library/PrivateFrameworks/"
    @"CoreBrightness.framework/CoreBrightness | grep -i keyboard";

static void fail(NSString *message) {
  fprintf(stderr, "keyboard_light: %s\n", message.UTF8String);
  exit(1);
}

static void requireSelectors(id brightnessClient) {
  for (NSString *selectorName in @[
         @"copyKeyboardBacklightIDs",
         @"isKeyboardBuiltIn:",
         @"brightnessForKeyboard:",
         @"setBrightness:forKeyboard:",
         @"enableAutoBrightness:forKeyboard:",
       ]) {
    if (![brightnessClient
            respondsToSelector:NSSelectorFromString(selectorName)]) {
      fail([NSString
          stringWithFormat:@"KeyboardBrightnessClient is missing %@. %@",
                           selectorName, kDyldHint]);
    }
  }
}

static float parseBrightness(const char *brightnessArgument) {
  char *parseEnd = NULL;
  float brightness = strtof(brightnessArgument, &parseEnd);
  if (parseEnd == brightnessArgument || *parseEnd != '\0' ||
      !isfinite(brightness) || brightness < 0.0f || brightness > 1.0f) {
    fail(@"usage: keyboard_light set <0.0-1.0>");
  }
  return brightness;
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/"
               "CoreBrightness",
               RTLD_NOW) == NULL) {
      fail(@"failed to load CoreBrightness.framework");
    }

    Class clientClass = NSClassFromString(@"KeyboardBrightnessClient");
    if (clientClass == Nil) {
      fail([@"KeyboardBrightnessClient not found. "
          stringByAppendingString:kDyldHint]);
    }

    id brightnessClientObject = [[clientClass alloc] init];
    requireSelectors(brightnessClientObject);
    id<KeyboardBrightnessClient> brightnessClient = brightnessClientObject;

    NSArray<NSNumber *> *keyboardIDs =
        [brightnessClient copyKeyboardBacklightIDs];
    if (keyboardIDs.count == 0) {
      fail(@"no keyboard backlight found");
    }
    unsigned long long keyboardID = keyboardIDs[0].unsignedLongLongValue;
    for (NSNumber *keyboardIDNumber in keyboardIDs) {
      unsigned long long candidateKeyboardID =
          keyboardIDNumber.unsignedLongLongValue;
      if ([brightnessClient isKeyboardBuiltIn:candidateKeyboardID]) {
        keyboardID = candidateKeyboardID;
        break;
      }
    }

    NSString *subcommand = argc > 1 ? @(argv[1]) : nil;
    if ([subcommand isEqualToString:@"get"]) {
      printf("%.4f\n", [brightnessClient brightnessForKeyboard:keyboardID]);
      return 0;
    }

    if ([subcommand isEqualToString:@"set"] && argc > 2) {
      float brightness = parseBrightness(argv[2]);
      if (![brightnessClient enableAutoBrightness:NO forKeyboard:keyboardID] ||
          ![brightnessClient setBrightness:brightness forKeyboard:keyboardID]) {
        fail(@"CoreBrightness refused the change");
      }
      return 0;
    }

    fail(@"usage: keyboard_light [get|set <0.0-1.0>]");
  }
}
