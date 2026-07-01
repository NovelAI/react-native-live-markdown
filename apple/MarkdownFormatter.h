#import <Foundation/Foundation.h>
#import <RNLiveMarkdown/MarkdownRange.h>
#import <RNLiveMarkdown/RCTMarkdownStyle.h>

NS_ASSUME_NONNULL_BEGIN

const NSAttributedStringKey RCTLiveMarkdownTextAttributeName = @"RCTLiveMarkdownText";

const NSAttributedStringKey RCTLiveMarkdownTextBackgroundAttributeName = @"RCTLiveMarkdownTextBackground";

const NSAttributedStringKey RCTLiveMarkdownBlockquoteDepthAttributeName = @"RCTLiveMarkdownBlockquoteDepth";

// NovelAI fork: stored on each chip's sentinel char; its value is the text the
// chip contributes to the clipboard on copy/cut (the macro expansion).
const NSAttributedStringKey RNLMChipCopyTextAttributeName = @"RNLMChipCopyText";

@interface MarkdownFormatter : NSObject

- (void)formatAttributedString:(nonnull NSMutableAttributedString *)attributedString
     withDefaultTextAttributes:(nonnull NSDictionary<NSAttributedStringKey, id> *)defaultTextAttributes
            withMarkdownRanges:(nonnull NSArray<MarkdownRange *> *)markdownRanges
             withMarkdownStyle:(nonnull RCTMarkdownStyle *)markdownStyle;

NS_ASSUME_NONNULL_END

@end
