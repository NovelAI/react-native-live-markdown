#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MarkdownRange : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic) NSRange range;
@property (nonatomic) NSUInteger depth;

// NovelAI fork: per-range style for the 'highlight' type. nil/0 when the parser
// range did not provide the corresponding field.
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic) CGFloat borderRadius;
// NovelAI fork: chip label (text drawn in place of the range) and the text the
// chip contributes to the clipboard on copy/cut (the macro expansion).
@property (nonatomic, strong, nullable) NSString *label;
@property (nonatomic, strong, nullable) NSString *clipboardText;
// NovelAI fork: chip visual metrics (points). nil border / 0 metrics = absent.
@property (nonatomic, strong, nullable) UIColor *borderColor;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) CGFloat paddingHorizontal;
@property (nonatomic) CGFloat fontScale;

- (instancetype)initWithType:(NSString *)type range:(NSRange)range depth:(NSUInteger)depth;

NS_ASSUME_NONNULL_END

@end
