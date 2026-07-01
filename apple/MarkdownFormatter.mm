#import "MarkdownFormatter.h"
#import <React/RCTFont.h>
#import <RNLiveMarkdown/RCTMarkdownTextBackgroundWithRange.h>

@implementation MarkdownFormatter

- (void)formatAttributedString:(nonnull NSMutableAttributedString *)attributedString
     withDefaultTextAttributes:(nonnull NSDictionary<NSAttributedStringKey, id> *)defaultTextAttributes
            withMarkdownRanges:(nonnull NSArray<MarkdownRange *> *)markdownRanges
             withMarkdownStyle:(nonnull RCTMarkdownStyle *)markdownStyle
{
  NSRange fullRange = NSMakeRange(0, attributedString.length);

  [attributedString beginEditing];

  [attributedString setAttributes:defaultTextAttributes range:fullRange];

  // We add a custom attribute to force a different comparison mode in swizzled `_textOf` method.
  [attributedString addAttribute:RCTLiveMarkdownTextAttributeName value:@(YES) range:fullRange];

  for (MarkdownRange *markdownRange in markdownRanges) {
    // NovelAI fork: 'highlight' ranges carry their own style, so they bypass
    // the type->markdownStyle lookup used by the built-in types.
    if ([markdownRange.type isEqualToString:@"highlight"]) {
      [self applyHighlightToAttributedString:attributedString
                                       range:markdownRange.range
                                       color:markdownRange.color
                             backgroundColor:markdownRange.backgroundColor
                                borderRadius:markdownRange.borderRadius];
      continue;
    }
    // NovelAI fork: 'chip' renders the range as an inline NSTextAttachment pill.
    if ([markdownRange.type isEqualToString:@"chip"]) {
      [self applyChipToAttributedString:attributedString
                          markdownRange:markdownRange
                  defaultTextAttributes:defaultTextAttributes];
      continue;
    }
    [self applyRangeToAttributedString:attributedString
                                  type:std::string([markdownRange.type UTF8String])
                                 range:markdownRange.range
                                 depth:markdownRange.depth
                         markdownStyle:markdownStyle
                 defaultTextAttributes:defaultTextAttributes];
  }

  [attributedString.string enumerateSubstringsInRange:fullRange
                                              options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                                           usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
    RCTApplyBaselineOffset(attributedString, enclosingRange);
  }];

  [attributedString fixAttributesInRange:fullRange];

  [attributedString endEditing];
}

- (void)applyRangeToAttributedString:(NSMutableAttributedString *)attributedString
                                type:(const std::string)type
                               range:(const NSRange)range
                               depth:(const int)depth
                       markdownStyle:(nonnull RCTMarkdownStyle *)markdownStyle
               defaultTextAttributes:(nonnull NSDictionary<NSAttributedStringKey, id> *)defaultTextAttributes
{
  if (type == "bold" || type == "italic" || type == "code" || type == "pre" || type == "h1" || type == "emoji") {
    UIFont *font = [attributedString attribute:NSFontAttributeName atIndex:range.location effectiveRange:NULL];
    if (type == "bold") {
      font = [RCTFont updateFont:font withWeight:@"bold"];
    } else if (type == "italic") {
      font = [RCTFont updateFont:font withStyle:@"italic"];
    } else if (type == "code") {
      font = [RCTFont updateFont:font withFamily:markdownStyle.codeFontFamily
                                            size:[NSNumber numberWithFloat:markdownStyle.codeFontSize]
                                          weight:nil
                                            style:nil
                                          variant:nil
                                  scaleMultiplier:0];
    } else if (type == "pre") {
      font = [RCTFont updateFont:font withFamily:markdownStyle.preFontFamily
                                            size:[NSNumber numberWithFloat:markdownStyle.preFontSize]
                                          weight:nil
                                          style:nil
                                        variant:nil
                                scaleMultiplier:0];
    } else if (type == "h1") {
      font = [RCTFont updateFont:font withFamily:nil
                                            size:[NSNumber numberWithFloat:markdownStyle.h1FontSize]
                                          weight:@"bold"
                                            style:nil
                                          variant:nil
                                  scaleMultiplier:0];
    } else if (type == "emoji") {
      font = [RCTFont updateFont:font withFamily:markdownStyle.emojiFontFamily
                                            size:[NSNumber numberWithFloat:markdownStyle.emojiFontSize]
                                          weight:nil
                                            style:nil
                                          variant:nil
                                  scaleMultiplier:0];
    }
    [attributedString addAttribute:NSFontAttributeName value:font range:range];
  }

  if (type == "syntax") {
    [attributedString addAttribute:NSForegroundColorAttributeName value:markdownStyle.syntaxColor range:range];
  } else if (type == "strikethrough") {
    [attributedString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:range];
  } else if (type == "code") {
    [attributedString addAttribute:NSForegroundColorAttributeName value:markdownStyle.codeColor range:range];
    [attributedString addAttribute:NSBackgroundColorAttributeName value:markdownStyle.codeBackgroundColor range:range];
  } else if (type == "mention-here") {
    [self applyMentionFormatting:attributedString
                           range:range
                 mentionColor:markdownStyle.mentionHereColor
                 backgroundColor:markdownStyle.mentionHereBackgroundColor
                    borderRadius:markdownStyle.mentionHereBorderRadius];
  } else if (type == "mention-user") {
    // TODO: change mention color when it mentions current user
    [self applyMentionFormatting:attributedString
                           range:range
                 mentionColor:markdownStyle.mentionUserColor
                 backgroundColor:markdownStyle.mentionUserBackgroundColor
                    borderRadius:markdownStyle.mentionUserBorderRadius];
  } else if (type == "mention-report") {
    [self applyMentionFormatting:attributedString
                           range:range
                 mentionColor:markdownStyle.mentionReportColor
                 backgroundColor:markdownStyle.mentionReportBackgroundColor
                    borderRadius:markdownStyle.mentionReportBorderRadius];
  } else if (type == "link") {
    [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:range];
    [attributedString addAttribute:NSForegroundColorAttributeName value:markdownStyle.linkColor range:range];
  } else if (type == "blockquote") {
    CGFloat indent = (markdownStyle.blockquoteMarginLeft + markdownStyle.blockquoteBorderWidth + markdownStyle.blockquotePaddingLeft) * depth;
    NSParagraphStyle *defaultParagraphStyle = defaultTextAttributes[NSParagraphStyleAttributeName];
    NSMutableParagraphStyle *paragraphStyle = defaultParagraphStyle != nil ? [defaultParagraphStyle mutableCopy] : [NSMutableParagraphStyle new];
    paragraphStyle.firstLineHeadIndent = indent;
    paragraphStyle.headIndent = indent;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    [attributedString addAttribute:RCTLiveMarkdownBlockquoteDepthAttributeName value:@(depth) range:range];
  } else if (type == "pre") {
    [attributedString addAttribute:NSForegroundColorAttributeName value:markdownStyle.preColor range:range];
    NSRange rangeForBackground = [[attributedString string] characterAtIndex:range.location] == '\n' ? NSMakeRange(range.location + 1, range.length - 1) : range;
    [attributedString addAttribute:NSBackgroundColorAttributeName value:markdownStyle.preBackgroundColor range:rangeForBackground];
    // TODO: pass background color and ranges to layout manager
  }
}

- (void)applyMentionFormatting:(NSMutableAttributedString *)attributedString
                         range:(const NSRange)range
               mentionColor:(UIColor *)mentionColor
               backgroundColor:(UIColor *)backgroundColor
                  borderRadius:(CGFloat)borderRadius
{
  [attributedString addAttribute:NSForegroundColorAttributeName value:mentionColor range:range];
  if (@available(iOS 16.0, *)) {
    RCTMarkdownTextBackground *textBackground = [[RCTMarkdownTextBackground alloc] init];
    textBackground.color = backgroundColor;
    textBackground.borderRadius = borderRadius;
    
    [attributedString addAttribute:RCTLiveMarkdownTextBackgroundAttributeName
                             value:textBackground
                             range:range];
  } else {
    [attributedString addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:range];
  }
}

// NovelAI fork: apply a 'highlight' range's per-range style. Foreground color
// and background are independent and either may be nil. A non-nil background
// uses the rounded text-background machinery (same as mentions) so emphasis
// tints and macro chips can have a border radius; alpha is carried by the
// color itself.
- (void)applyHighlightToAttributedString:(NSMutableAttributedString *)attributedString
                                   range:(const NSRange)range
                                   color:(nullable UIColor *)color
                         backgroundColor:(nullable UIColor *)backgroundColor
                            borderRadius:(const CGFloat)borderRadius
{
  if (color != nil) {
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];
  }
  if (backgroundColor != nil) {
    if (@available(iOS 16.0, *)) {
      RCTMarkdownTextBackground *textBackground = [[RCTMarkdownTextBackground alloc] init];
      textBackground.color = backgroundColor;
      textBackground.borderRadius = borderRadius;
      [attributedString addAttribute:RCTLiveMarkdownTextBackgroundAttributeName value:textBackground range:range];
    } else {
      [attributedString addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:range];
    }
  }
}

// NovelAI fork: render a rounded pill image containing `label` (subtle fill +
// border, sized to the label). All metrics are in points, supplied by JS.
static UIImage *RNLMRenderChipImage(NSString *label, UIColor *textColor, UIColor *bgColor, UIColor *_Nullable borderColor, CGFloat borderWidth, CGFloat radius, CGFloat paddingH, UIFont *font) {
  NSDictionary<NSAttributedStringKey, id> *attrs = @{NSFontAttributeName : font, NSForegroundColorAttributeName : textColor};
  CGSize textSize = [label sizeWithAttributes:attrs];
  const CGFloat inset = borderColor != nil ? borderWidth : 0;
  const CGFloat w = ceil(textSize.width) + paddingH * 2 + inset * 2;
  const CGFloat h = ceil(font.lineHeight) + inset * 2;
  const CGRect rect = CGRectMake(0, 0, w, h);
  const CGRect strokeRect = CGRectInset(rect, inset / 2.0, inset / 2.0);

  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rect.size];
  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
    UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
    [bgColor setFill];
    [fillPath fill];
    if (borderColor != nil && borderWidth > 0) {
      UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:radius];
      strokePath.lineWidth = borderWidth;
      [borderColor setStroke];
      [strokePath stroke];
    }
    [label drawAtPoint:CGPointMake(paddingH + inset, (h - ceil(textSize.height)) / 2.0) withAttributes:attrs];
  }];
}

// NovelAI fork: render a chip range (a single U+FFFC sentinel) as an inline
// NSTextAttachment pill containing `label`: atomic and label-sized. Visual
// metrics come from the range (JS-driven). The label uses the range's `color`,
// or the editor's text colour when absent. `clipboardText` is stashed on the
// sentinel so copy/cut can emit the macro's expansion instead of the sentinel.
- (void)applyChipToAttributedString:(NSMutableAttributedString *)attributedString
                      markdownRange:(nonnull MarkdownRange *)markdownRange
              defaultTextAttributes:(nonnull NSDictionary<NSAttributedStringKey, id> *)defaultTextAttributes
{
  NSString *label = markdownRange.label;
  if (label == nil || markdownRange.range.length == 0) {
    return;
  }
  UIFont *baseFont = defaultTextAttributes[NSFontAttributeName] ?: [UIFont systemFontOfSize:UIFont.systemFontSize];
  UIFont *font = markdownRange.fontScale > 0 ? [baseFont fontWithSize:baseFont.pointSize * markdownRange.fontScale] : baseFont;
  UIColor *textColor = markdownRange.color ?: defaultTextAttributes[NSForegroundColorAttributeName] ?: UIColor.labelColor;
  UIColor *bgColor = markdownRange.backgroundColor ?: UIColor.clearColor;
  UIImage *pill = RNLMRenderChipImage(label, textColor, bgColor, markdownRange.borderColor, markdownRange.borderWidth, markdownRange.borderRadius, markdownRange.paddingHorizontal, font);

  NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
  attachment.image = pill;
  // Vertically center the pill on the line using the base (line) font.
  attachment.bounds = CGRectMake(0, (baseFont.capHeight - pill.size.height) / 2.0, pill.size.width, pill.size.height);

  [attributedString addAttribute:NSAttachmentAttributeName value:attachment range:markdownRange.range];
  [attributedString addAttribute:RNLMChipCopyTextAttributeName value:(markdownRange.clipboardText ?: @"") range:markdownRange.range];
}

static void RCTApplyBaselineOffset(NSMutableAttributedString *attributedText, NSRange attributedTextRange)
{
  __block CGFloat maximumLineHeight = 0;

  [attributedText enumerateAttribute:NSParagraphStyleAttributeName
                             inRange:attributedTextRange
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(NSParagraphStyle *paragraphStyle, __unused NSRange range, __unused BOOL *stop) {
    if (!paragraphStyle) {
      return;
    }

    maximumLineHeight = MAX(paragraphStyle.maximumLineHeight, maximumLineHeight);
  }];

  if (maximumLineHeight == 0) {
    // `lineHeight` was not specified, nothing to do.
    return;
  }

  __block CGFloat maximumFontLineHeight = 0;

  [attributedText enumerateAttribute:NSFontAttributeName
                             inRange:attributedTextRange
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(UIFont *font, NSRange range, __unused BOOL *stop) {
    if (!font) {
      return;
    }

    maximumFontLineHeight = MAX(font.lineHeight, maximumFontLineHeight);
  }];

  if (maximumLineHeight < maximumFontLineHeight) {
    return;
  }

  CGFloat baseLineOffset = (maximumLineHeight - maximumFontLineHeight) / 2.0;
  [attributedText addAttribute:NSBaselineOffsetAttributeName
                         value:@(baseLineOffset)
                         range:attributedTextRange];
}

@end
