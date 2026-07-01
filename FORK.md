# Vendored fork of `@expensify/react-native-live-markdown`

Upstream: https://github.com/Expensify/react-native-live-markdown @ `v0.1.329`
(commit `55901ca`). MIT licensed.

This is a **vendored** copy (not an npm dependency) so we can edit the native
code. The app depends on it via `"link:./modules/react-native-live-markdown"`.
Metro/TS consume `src/` directly (`source`/`react-native`/`types` point at
`src/index`), so there is **no `bob` build step**. Edit and rebuild the native
app (`expo run:ios` / `expo run:android`).

## Why we forked

Upstream styles text ranges by a **fixed `type` enum**, with the visual style
looked up from a global `markdownStyle` prop keyed by type. The prompt editor
needs **arbitrary, per-range** styling and **atomic chips**, and the fixed
palette can express neither:

- **Emphasis tints**: a continuous color/opacity gradient driven by parsing
  `{}` / `[]` / `N::`.
- **Macro chips**: each `⌜macro:id⌟` reference renders as a single, atomic,
  tinted pill (deletes/selects as one unit) showing a label, not raw text.

## New range types

A parser worklet range may use two fork-added types, each carrying its own style
on the range (all colors are **ARGB integers computed in the worklet** via plain
arithmetic, so worklet-safe; every field is optional):

```ts
{ type: 'highlight', start, length,
  color?, backgroundColor?,  // ARGB ints, alpha carries opacity
  borderRadius? }            // rounds the background (tint / mention)

{ type: 'chip', start, length,      // `length` covers one U+FFFC sentinel
  label,                            // text drawn inside the pill (replaces the range text)
  copyText?,                        // what the chip contributes to the clipboard
  color?, backgroundColor?, borderColor?,
  borderWidth?, borderRadius?, paddingHorizontal?, fontScale? }
```

- **`highlight`** tints a text range (reusing upstream's rounded text-background
  machinery, so tints can round their corners). Used for emphasis.
- **`chip`** *replaces* the range's text with `label` drawn inside a rounded pill,
  rendered atomically. iOS uses an `NSTextAttachment` (which only renders on a
  **U+FFFC** object-replacement char, so each chip is exactly one sentinel char);
  Android uses a `ReplacementSpan` (atomic for free). Chip metrics are JS-driven
  (dp on Android, points on iOS, for matching physical size); if `color` is
  omitted the label uses the editor's text color.

Built-in types and cursor/IME/selection sync are unchanged from upstream.

## Clipboard expansion

Copy/cut emit the **expanded** prompt: each chip's `copyText` is substituted for
its sentinel char, so pasting elsewhere yields real text, not `￼`.

- **iOS**: swizzles `copy:`/`cut:` on `RCTUITextView`
  (`apple/RCTUITextView+MarkdownClipboard.mm`), reading the chip copy-text
  attribute off `textStorage`. The swizzle is installed explicitly via
  `RNLMInstallMarkdownClipboard()` from the decorator (a category `+load` isn't
  linked from the static pod).
- **Android**: a selection `ActionMode.Callback`
  (`MarkdownClipboardActionModeCallback.java`) on the `ReactEditText`, plus a
  `View.OnKeyListener` for hardware Ctrl+C/X; both wired in
  `MarkdownTextInputDecoratorView.java`.

## `maxScrollHeight` decorator prop

A new codegen prop on the decorator (`Float`, dp). When `> 0` it's the height cap
below which the field must not scroll. RN's `ReactEditText` forces a
scroll-to-caret on grow (`isLayoutRequested()` returns false), which jumps the
text up a line; on **Android** this pins the EditText scroll to 0 while the
content fits under the cap, suppressing that jump. **iOS** ignores it (it already
honors `scrollEnabled`).

## Files changed vs upstream

- `src/commonTypes.ts`: added `'highlight'` and `'chip'` to `MarkdownType`; added
  the optional per-range style fields above to `MarkdownRange`.
- `src/MarkdownTextInputDecoratorViewNativeComponent.ts`: added the
  `maxScrollHeight` codegen prop.
- `src/MarkdownTextInput.tsx`: forwards `maxScrollHeight` to the decorator.
- **iOS**
  - `apple/MarkdownRange.h` / `.mm`: the per-range style fields.
  - `apple/MarkdownParser.mm`: reads the optional fields off each JSI range;
    `RNLMColorFromARGB()` converts ARGB int → UIColor.
  - `apple/MarkdownFormatter.h` / `.mm`: `highlight` (per-range fg/bg) and `chip`
    (builds an `NSTextAttachment` pill image; `RNLMChipCopyTextAttributeName`
    carries the copy text).
  - `apple/RCTUITextView+MarkdownClipboard.mm`: **new**, the copy/cut swizzle.
  - `apple/MarkdownTextInputDecoratorComponentView.mm`: installs the clipboard
    swizzle when it attaches the text view.
- **Android**
  - `android/.../MarkdownRange.java`: the per-range style fields.
  - `android/.../MarkdownParser.java`: reads them off each JSON range (via `long`
    to preserve the full 32-bit ARGB pattern). The C++ `nativeParse` uses
    `JSON.stringify(output)`, so the fields serialize automatically, with no C++ change.
  - `android/.../MarkdownFormatter.java`: `highlight` and `chip` cases.
  - `android/.../spans/MarkdownChipSpan.java`: **new**, the `ReplacementSpan` pill.
  - `android/.../MarkdownClipboardActionModeCallback.java`: **new**, copy/cut menu.
  - `android/.../MarkdownTextInputDecoratorView.java`: installs the clipboard
    callback + Ctrl+C/X key listener, and the `maxScrollHeight` scroll-pin.
  - `android/.../MarkdownTextInputDecoratorViewManager.java`: `maxScrollHeight`
    `@ReactProp`.

## Removed from upstream

- The built-in **ExpensiMark** parser (`src/parseExpensiMark.ts`) and its
  `expensify-common` / `html-entities` (+ worklet patch) dependencies, since we
  ship our own parser worklet. `src/__tests__/`, `example/`, `WebExample/`, and the
  publishing/build tooling were also dropped. `package.json` keeps the upstream
  `name`/`author`/`homepage` because the podspec reads them.

## Re-syncing with upstream

A small, well-isolated diff. To pull a newer upstream: re-clone, re-apply the
changes listed above (grep for `NovelAI fork`), and re-run the trim steps.
