# Fork notes

Fork of [Expensify/react-native-live-markdown](https://github.com/Expensify/react-native-live-markdown)
at `v0.1.329` (commit `55901ca`). MIT licensed; upstream license and attribution are kept.

Consumed as a git dependency (`#novelai-fork`). No build step: `main`/`module`/`types`
point at `src/`, and the native code compiles through the podspec and Gradle
autolinking. Native changes need a rebuild of the consuming app.

## Changes vs upstream

- Two new range types, each carrying its own style fields on the range:
  `highlight` (per-range foreground/background tint, optional corner radius) and
  `chip` (replaces a one-character U+FFFC range with an atomic labeled pill;
  `NSTextAttachment` on iOS, `ReplacementSpan` on Android).
- Clipboard expansion: copy/cut substitute each chip's `copyText` for its
  sentinel character.
- `maxScrollHeight` decorator prop (Android): pins the EditText scroll while the
  content fits under the cap, avoiding the scroll-to-caret jump on grow.
- Removed the ExpensiMark parser and its dependencies, the example apps, tests,
  and publishing tooling.

Search the sources for `NovelAI fork` to find every change.

## Syncing with upstream

Add upstream as a remote, merge its tag into `novelai-fork`, resolve conflicts
in the marked files, bump the `-novelai-fork` version suffix.
