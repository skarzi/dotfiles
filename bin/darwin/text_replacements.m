#import <Foundation/Foundation.h>
#import <dlfcn.h>

// Declared locally so we can message `KeyboardServices` without linking it.
// NOTE: Private APIs (stable since macOS 10.12, verified on macOS 26).
// Writes go through `keyboardservicesd`, which owns the store and sync.
@protocol KSTextReplacementEntry <NSObject>
@property(copy, nonatomic) NSString *phrase;
@property(copy, nonatomic) NSString *shortcut;
@property(retain, nonatomic) NSDate *timestamp;
@property(nonatomic) BOOL needsSaveToCloud;
@end

@protocol KSTextReplacementClientStore <NSObject>
- (void)addEntries:(NSArray *)entriesToAdd
            removeEntries:(NSArray *)entriesToRemove
    withCompletionHandler:(void (^)(NSError *error))completionHandler;
@end

static NSString *const kDyldHint =
    @"Re-discover with:\n"
    @"  dyld_info -exports /System/Library/PrivateFrameworks/"
    @"KeyboardServices.framework/KeyboardServices | grep -i textreplacement";

static void fail(NSString *message) {
  fprintf(stderr, "text_replacements: %s\n", message.UTF8String);
  exit(1);
}

static Class gEntryClass = Nil;

static id<KSTextReplacementEntry> makeEntry(NSString *shortcut,
                                            NSString *phrase) {
  id<KSTextReplacementEntry> entry = [[gEntryClass alloc] init];
  entry.shortcut = shortcut;
  entry.phrase = phrase;
  entry.timestamp = [NSDate date];
  entry.needsSaveToCloud = YES;
  return entry;
}

// NOTE: Read state from the defaults mirror: store queries return empty
// for third-party callers. No mirror would just make `apply` re-add all.
static NSDictionary<NSString *, NSString *> *currentReplacements(void) {
  NSMutableDictionary<NSString *, NSString *> *phraseByShortcut =
      [NSMutableDictionary dictionary];
  NSArray *mirrorEntries = [[NSUserDefaults standardUserDefaults]
      arrayForKey:@"NSUserDictionaryReplacementItems"];
  for (id mirrorEntry in mirrorEntries) {
    if (![mirrorEntry isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    NSString *shortcut = mirrorEntry[@"replace"];
    NSString *phrase = mirrorEntry[@"with"];
    if ([shortcut isKindOfClass:[NSString class]] &&
        [phrase isKindOfClass:[NSString class]]) {
      phraseByShortcut[shortcut] = phrase;
    }
  }
  return phraseByShortcut;
}

static NSArray<NSDictionary *> *desiredReplacements(NSString *plistPath) {
  NSData *plistContents = [NSData dataWithContentsOfFile:plistPath];
  if (plistContents == nil) {
    fail([NSString stringWithFormat:@"cannot read %@", plistPath]);
  }
  NSError *parseError = nil;
  id parsedPlist =
      [NSPropertyListSerialization propertyListWithData:plistContents
                                                options:0
                                                 format:NULL
                                                  error:&parseError];
  if (![parsedPlist isKindOfClass:[NSArray class]]) {
    fail([NSString stringWithFormat:@"%@ is not a plist array: %@", plistPath,
                                    parseError.localizedDescription]);
  }
  for (id desiredEntry in (NSArray *)parsedPlist) {
    if (![desiredEntry isKindOfClass:[NSDictionary class]] ||
        ![desiredEntry[@"shortcut"] isKindOfClass:[NSString class]] ||
        ![desiredEntry[@"phrase"] isKindOfClass:[NSString class]] ||
        [desiredEntry[@"shortcut"] length] == 0 ||
        [desiredEntry[@"phrase"] length] == 0) {
      fail([NSString stringWithFormat:@"entries in %@ need non-empty string "
                                      @"'shortcut' and 'phrase' keys",
                                      plistPath]);
    }
  }
  return parsedPlist;
}

static int applyReplacements(NSString *plistPath,
                             id<KSTextReplacementClientStore> store) {
  NSDictionary<NSString *, NSString *> *installedPhraseByShortcut =
      currentReplacements();
  NSMutableArray *entriesToAdd = [NSMutableArray array];
  NSMutableArray *entriesToRemove = [NSMutableArray array];
  for (NSDictionary *desiredEntry in desiredReplacements(plistPath)) {
    NSString *shortcut = desiredEntry[@"shortcut"];
    NSString *phrase = desiredEntry[@"phrase"];
    NSString *installedPhrase = installedPhraseByShortcut[shortcut];
    if (installedPhrase == nil) {
      [entriesToAdd addObject:makeEntry(shortcut, phrase)];
    } else if (![installedPhrase isEqualToString:phrase]) {
      [entriesToRemove addObject:makeEntry(shortcut, installedPhrase)];
      [entriesToAdd addObject:makeEntry(shortcut, phrase)];
    }
  }
  // NOTE: Add/update only. Undeclared entries (possibly iCloud-synced)
  // are never removed; plist removals don't delete locally.
  if (entriesToAdd.count == 0 && entriesToRemove.count == 0) {
    printf("text_replacements: already up to date\n");
    return 0;
  }
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block NSError *resultError = nil;
  [store addEntries:entriesToAdd
              removeEntries:entriesToRemove
      withCompletionHandler:^(NSError *error) {
        resultError = error;
        dispatch_semaphore_signal(semaphore);
      }];
  if (dispatch_semaphore_wait(
          semaphore, dispatch_time(DISPATCH_TIME_NOW, 5LL * NSEC_PER_SEC)) !=
      0) {
    fail(@"timed out waiting for keyboardservicesd");
  }
  // NOTE: The service reports success as an error with code 0.
  if (resultError != nil && resultError.code != 0) {
    fail([NSString stringWithFormat:@"keyboardservicesd refused the "
                                    @"change: %@",
                                    resultError.localizedDescription]);
  }
  printf("text_replacements: applied %lu addition(s), %lu update(s)\n",
         (unsigned long)entriesToAdd.count,
         (unsigned long)entriesToRemove.count);
  return 0;
}

static int listReplacements(void) {
  NSDictionary<NSString *, NSString *> *phraseByShortcut =
      currentReplacements();
  NSArray<NSString *> *shortcuts = [phraseByShortcut.allKeys
      sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
  for (NSString *shortcut in shortcuts) {
    printf("%s -> %s\n", shortcut.UTF8String,
           phraseByShortcut[shortcut].UTF8String);
  }
  return 0;
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (dlopen("/System/Library/PrivateFrameworks/"
               "KeyboardServices.framework/KeyboardServices",
               RTLD_NOW) == NULL) {
      fail(@"failed to load KeyboardServices.framework");
    }
    Class storeClass = NSClassFromString(@"_KSTextReplacementClientStore");
    gEntryClass = NSClassFromString(@"_KSTextReplacementEntry");
    if (storeClass == Nil || gEntryClass == Nil) {
      fail([@"KeyboardServices text replacement classes not found. "
          stringByAppendingString:kDyldHint]);
    }
    id<KSTextReplacementClientStore> store = [[storeClass alloc] init];
    if (![store respondsToSelector:@selector(addEntries:removeEntries:
                                             withCompletionHandler:)]) {
      fail([@"_KSTextReplacementClientStore is missing addEntries:. "
          stringByAppendingString:kDyldHint]);
    }

    NSString *subcommand = argc > 1 ? @(argv[1]) : nil;
    if ([subcommand isEqualToString:@"apply"] && argc > 2) {
      return applyReplacements(@(argv[2]), store);
    }
    if ([subcommand isEqualToString:@"list"]) {
      return listReplacements();
    }
    fail(@"usage: text_replacements [apply <replacements.plist>|list]");
  }
}
