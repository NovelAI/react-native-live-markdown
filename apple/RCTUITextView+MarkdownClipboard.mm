#import <React/RCTUITextView.h>
#import <RNLiveMarkdown/MarkdownFormatter.h> // RNLMChipCopyTextAttributeName
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Defined here; forward-declared by callers (the decorator). No header needed.
void RNLMInstallMarkdownClipboard(void);

// NovelAI fork: make copy/cut emit a chip's copy text (the macro expansion)
// instead of the bare U+FFFC sentinel. We swizzle copy:/cut: on RCTUITextView
// and only take over when the selection actually contains a chip; otherwise we
// call through to the system behaviour, so ordinary text inputs are unaffected.

static void RNLMSwizzle(Class cls, SEL originalSelector, SEL swizzledSelector) {
  Method originalMethod = class_getInstanceMethod(cls, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
  if (originalMethod == NULL || swizzledMethod == NULL) {
    return;
  }
  // Install the override on RCTUITextView specifically (copy:/cut: are inherited
  // from UIResponder, so add the method here rather than exchanging the parent's).
  BOOL didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
  if (didAddMethod) {
    class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

// Build the clipboard string for the current selection, replacing each chip
// sentinel with its copy text. Returns nil when the selection contains no chip
// (so the caller falls back to the default copy/cut).
static NSString *RNLMExpandedStringForSelection(UITextView *textView) {
  UITextRange *selection = textView.selectedTextRange;
  if (selection == nil || selection.empty) {
    return nil;
  }
  NSInteger start = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selection.start];
  NSInteger length = [textView offsetFromPosition:selection.start toPosition:selection.end];
  if (start < 0 || length <= 0) {
    return nil;
  }
  // Read from textStorage (where the markdown formatting, including our chip
  // attribute, is applied); RCTUITextView.attributedText does not reflect it.
  NSAttributedString *attributedText = textView.textStorage;
  if (attributedText == nil) {
    return nil;
  }
  NSRange range = NSMakeRange((NSUInteger)start, (NSUInteger)length);
  if (NSMaxRange(range) > attributedText.length) {
    return nil;
  }

  __block BOOL hasChip = NO;
  NSMutableString *result = [NSMutableString string];
  [attributedText enumerateAttribute:RNLMChipCopyTextAttributeName
                             inRange:range
                             options:0
                          usingBlock:^(id _Nullable value, NSRange subRange, __unused BOOL *stop) {
    if (value != nil) {
      hasChip = YES;
      NSString *copyText = (NSString *)value;
      // A run may hold several adjacent same-macro chips; emit one per sentinel.
      for (NSUInteger i = 0; i < subRange.length; i++) {
        [result appendString:copyText];
      }
    } else {
      [result appendString:[attributedText.string substringWithRange:subRange]];
    }
  }];

  return hasChip ? result : nil;
}

void RNLMInstallMarkdownClipboard(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    RNLMSwizzle([RCTUITextView class], @selector(copy:), @selector(liveMarkdown_copy:));
    RNLMSwizzle([RCTUITextView class], @selector(cut:), @selector(liveMarkdown_cut:));
  });
}

@implementation RCTUITextView (MarkdownClipboard)

+ (void)load {
  RNLMInstallMarkdownClipboard();
}

- (void)liveMarkdown_copy:(id)sender {
  NSString *expanded = RNLMExpandedStringForSelection(self);
  if (expanded != nil) {
    UIPasteboard.generalPasteboard.string = expanded;
  } else {
    [self liveMarkdown_copy:sender]; // original implementation (post-swizzle)
  }
}

- (void)liveMarkdown_cut:(id)sender {
  NSString *expanded = RNLMExpandedStringForSelection(self);
  if (expanded != nil) {
    UIPasteboard.generalPasteboard.string = expanded;
    UITextRange *selection = self.selectedTextRange;
    if (selection != nil && !selection.empty) {
      [self replaceRange:selection withText:@""];
    }
  } else {
    [self liveMarkdown_cut:sender]; // original implementation (post-swizzle)
  }
}

@end
