#import "MarkdownParser.h"
#import <RNLiveMarkdown/MarkdownGlobal.h>
#import <React/RCTLog.h>

// NovelAI fork: convert an ARGB integer (0xAARRGGBB, as emitted by a parser
// worklet) into a UIColor. Read as a double from JSI and truncated to uint32.
static UIColor *RNLMColorFromARGB(double value) {
  const uint32_t argb = static_cast<uint32_t>(value);
  const CGFloat a = ((argb >> 24) & 0xFF) / 255.0;
  const CGFloat r = ((argb >> 16) & 0xFF) / 255.0;
  const CGFloat g = ((argb >> 8) & 0xFF) / 255.0;
  const CGFloat b = (argb & 0xFF) / 255.0;
  return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

@implementation MarkdownParser {
  NSString *_prevText;
  NSNumber *_prevParserId;
  NSArray<MarkdownRange *> *_prevMarkdownRanges;
}

- (NSArray<MarkdownRange *> *)parse:(nonnull NSString *)text
                       withParserId:(nonnull NSNumber *)parserId
{
  @synchronized (self) {
    if ([text isEqualToString:_prevText] && [parserId isEqualToNumber:_prevParserId]) {
      return _prevMarkdownRanges;
    }

    const auto &markdownRuntime = expensify::livemarkdown::getMarkdownRuntime();
    jsi::Runtime &rt = markdownRuntime->getJSIRuntime();

    std::shared_ptr<SerializableWorklet> markdownWorklet;
    try {
      markdownWorklet = expensify::livemarkdown::getMarkdownWorklet([parserId intValue]);
    } catch (const std::out_of_range &error) {
      _prevText = [NSString stringWithString:text];
      _prevParserId = parserId;
      _prevMarkdownRanges = @[];
      return _prevMarkdownRanges;
    }

    const auto &input = jsi::String::createFromUtf8(rt, [text UTF8String]);

    jsi::Value output;
    try {
      output = markdownRuntime->runGuarded(markdownWorklet, input);
    } catch (const jsi::JSError &error) {
      // Skip formatting, runGuarded will show the error in LogBox
      _prevText = [NSString stringWithString:text];
      _prevParserId = parserId;
      _prevMarkdownRanges = @[];
      return _prevMarkdownRanges;
    }

    NSMutableArray<MarkdownRange *> *markdownRanges = [[NSMutableArray alloc] init];
    try {
      const auto &ranges = output.asObject(rt).asArray(rt);
      for (size_t i = 0, n = ranges.size(rt); i < n; ++i) {
        const auto &item = ranges.getValueAtIndex(rt, i).asObject(rt);
        const auto &type = item.getProperty(rt, "type").asString(rt).utf8(rt);
        const auto &start = static_cast<int>(item.getProperty(rt, "start").asNumber());
        const auto &length = static_cast<int>(item.getProperty(rt, "length").asNumber());
        const auto &depth = item.hasProperty(rt, "depth") ? static_cast<int>(item.getProperty(rt, "depth").asNumber()) : 1;

        if (length == 0 || start + length > text.length) {
          continue;
        }

        NSRange range = NSMakeRange(start, length);
        MarkdownRange *markdownRange = [[MarkdownRange alloc] initWithType:@(type.c_str()) range:range depth:depth];

        // NovelAI fork: read optional per-range style for 'highlight' ranges.
        if (item.hasProperty(rt, "color")) {
          markdownRange.color = RNLMColorFromARGB(item.getProperty(rt, "color").asNumber());
        }
        if (item.hasProperty(rt, "backgroundColor")) {
          markdownRange.backgroundColor = RNLMColorFromARGB(item.getProperty(rt, "backgroundColor").asNumber());
        }
        if (item.hasProperty(rt, "borderRadius")) {
          markdownRange.borderRadius = static_cast<CGFloat>(item.getProperty(rt, "borderRadius").asNumber());
        }
        if (item.hasProperty(rt, "label")) {
          markdownRange.label = @(item.getProperty(rt, "label").asString(rt).utf8(rt).c_str());
        }
        if (item.hasProperty(rt, "copyText")) {
          markdownRange.clipboardText = @(item.getProperty(rt, "copyText").asString(rt).utf8(rt).c_str());
        }
        if (item.hasProperty(rt, "borderColor")) {
          markdownRange.borderColor = RNLMColorFromARGB(item.getProperty(rt, "borderColor").asNumber());
        }
        if (item.hasProperty(rt, "borderWidth")) {
          markdownRange.borderWidth = static_cast<CGFloat>(item.getProperty(rt, "borderWidth").asNumber());
        }
        if (item.hasProperty(rt, "paddingHorizontal")) {
          markdownRange.paddingHorizontal = static_cast<CGFloat>(item.getProperty(rt, "paddingHorizontal").asNumber());
        }
        if (item.hasProperty(rt, "fontScale")) {
          markdownRange.fontScale = static_cast<CGFloat>(item.getProperty(rt, "fontScale").asNumber());
        }

        [markdownRanges addObject:markdownRange];
      }
    } catch (const jsi::JSError &error) {
      RCTLogWarn(@"[react-native-live-markdown] Incorrect schema of worklet parser output: %s", error.getMessage().c_str());
      _prevText = [NSString stringWithString:text];
      _prevParserId = parserId;
      _prevMarkdownRanges = @[];
      return _prevMarkdownRanges;
    }

    _prevText = [NSString stringWithString:text];
    _prevParserId = parserId;
    _prevMarkdownRanges = markdownRanges;
    return _prevMarkdownRanges;
  }
}

@end
