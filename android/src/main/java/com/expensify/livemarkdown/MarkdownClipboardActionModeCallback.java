package com.expensify.livemarkdown;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.text.Editable;
import android.view.ActionMode;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.EditText;

import androidx.annotation.Nullable;

import com.expensify.livemarkdown.spans.MarkdownChipSpan;

/**
 * NovelAI fork: intercept Copy/Cut on the editor's selection menu so chips
 * contribute their copy text (the macro expansion) instead of the bare U+FFFC
 * sentinel. Anything other than copy/cut (and copy/cut over selections with no
 * chip) is delegated to the EditText's previous callback (or the default).
 */
public class MarkdownClipboardActionModeCallback implements ActionMode.Callback {
  private final EditText mEditText;
  private final @Nullable ActionMode.Callback mDelegate;

  public MarkdownClipboardActionModeCallback(EditText editText, @Nullable ActionMode.Callback delegate) {
    mEditText = editText;
    mDelegate = delegate;
  }

  @Override
  public boolean onCreateActionMode(ActionMode mode, Menu menu) {
    return mDelegate != null ? mDelegate.onCreateActionMode(mode, menu) : true;
  }

  @Override
  public boolean onPrepareActionMode(ActionMode mode, Menu menu) {
    return mDelegate != null && mDelegate.onPrepareActionMode(mode, menu);
  }

  @Override
  public boolean onActionItemClicked(ActionMode mode, MenuItem item) {
    int id = item.getItemId();
    if (id == android.R.id.copy || id == android.R.id.cut) {
      if (handleClipboard(id == android.R.id.cut)) {
        mode.finish();
        return true;
      }
    }
    return mDelegate != null && mDelegate.onActionItemClicked(mode, item);
  }

  @Override
  public void onDestroyActionMode(ActionMode mode) {
    if (mDelegate != null) {
      mDelegate.onDestroyActionMode(mode);
    }
  }

  // Returns false (deferring to the default) when the selection has no chip.
  boolean handleClipboard(boolean isCut) {
    Editable text = mEditText.getText();
    if (text == null) {
      return false;
    }
    int start = mEditText.getSelectionStart();
    int end = mEditText.getSelectionEnd();
    if (start < 0 || end <= start) {
      return false;
    }
    if (text.getSpans(start, end, MarkdownChipSpan.class).length == 0) {
      return false;
    }

    StringBuilder builder = new StringBuilder();
    for (int i = start; i < end; i++) {
      MarkdownChipSpan[] chip = text.getSpans(i, i + 1, MarkdownChipSpan.class);
      if (chip.length > 0) {
        builder.append(chip[0].getCopyText());
      } else {
        builder.append(text.charAt(i));
      }
    }

    Context context = mEditText.getContext();
    ClipboardManager clipboard = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
    if (clipboard != null) {
      clipboard.setPrimaryClip(ClipData.newPlainText(null, builder.toString()));
    }
    if (isCut) {
      text.replace(start, end, "");
    }
    return true;
  }
}
