type MarkdownType =
  | 'bold'
  | 'italic'
  | 'strikethrough'
  | 'emoji'
  | 'mention-here'
  | 'mention-user'
  | 'mention-short'
  | 'mention-report'
  | 'link'
  | 'code'
  | 'pre'
  | 'blockquote'
  | 'h1'
  | 'syntax'
  | 'inline-image'
  | 'codeblock'
  // NovelAI fork: a generic decoration whose visual attributes are carried
  // per-range (see `color`/`backgroundColor`/`borderRadius` below) instead of
  // being looked up by type in `markdownStyle`. Lets a parser worklet emit
  // arbitrary continuous colors/opacities (e.g. emphasis tints, macro chips).
  | 'highlight'
  // NovelAI fork: an atomic chip. Like 'highlight', but the range's text is
  // visually *replaced* by `label` drawn inside a rounded pill (Android
  // ReplacementSpan). Used to render macro refs (`⌜macro:id⌟`) as `@Label`.
  | 'chip';

interface MarkdownRange {
  type: MarkdownType;
  start: number;
  length: number;
  depth?: number;
  syntaxType?: 'opening' | 'closing';
  // NovelAI fork: per-range styling for the 'highlight' type. Colors are ARGB
  // integers (0xAARRGGBB) computed in the parser worklet; alpha carries
  // opacity. `borderRadius` (px) rounds the background like a chip/mention.
  // All optional; omitted fields are simply not applied.
  color?: number;
  backgroundColor?: number;
  borderRadius?: number;
  // NovelAI fork: text drawn inside a 'chip' (replacing the range's own text).
  label?: string;
  // NovelAI fork: the text a 'chip' contributes to the clipboard on copy/cut
  // (e.g. a macro's expansion), in place of the bare sentinel char.
  copyText?: string;
  // NovelAI fork: 'chip' visual metrics, all JS-driven so the look can be tuned
  // without a native rebuild. Lengths are in dp/points (Android converts to px;
  // iOS uses them as points) so chips render at the same physical size on both.
  // If `color` is omitted, the chip label uses the editor's text colour.
  borderColor?: number;
  borderWidth?: number;
  paddingHorizontal?: number;
  fontScale?: number;
}

type InlineImagesInputProps = {
  addAuthTokenToImageURLCallback?: (url: string) => string;
  imagePreviewAuthRequiredURLs?: string[];
};

export type {MarkdownType, MarkdownRange, InlineImagesInputProps};
