package com.expensify.livemarkdown;

import android.content.Context;
import android.text.Editable;
import android.text.Layout;
import android.text.SpannableStringBuilder;
import android.text.TextWatcher;

import android.view.ActionMode;
import android.view.KeyEvent;
import android.view.View;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.uimanager.PixelUtil;
import com.facebook.react.views.textinput.ReactEditText;
import com.facebook.react.views.view.ReactViewGroup;

public class MarkdownTextInputDecoratorView extends ReactViewGroup {

  public MarkdownTextInputDecoratorView(Context context) {
    super(context);
  }

  private MarkdownStyle mMarkdownStyle;

  private int mParserId;

  private MarkdownUtils mMarkdownUtils;

  private ReactEditText mReactEditText;

  private TextWatcher mTextWatcher;

  private ActionMode.Callback mOriginalActionModeCallback;

  private MarkdownClipboardActionModeCallback mClipboardCallback;

  // NovelAI fork: height cap (px) below which the field must not scroll. RN
  // forces a scroll-to-caret on grow (ReactEditText.isLayoutRequested()=false),
  // which jumps the text; we pin scroll to 0 while content fits under the cap.
  private float mMaxScrollHeightPx = 0;

  @Override
  protected void onAttachedToWindow() {
    super.onAttachedToWindow();

    View child = getChildAt(0);
    if (child instanceof ReactEditText) {
      mMarkdownUtils = new MarkdownUtils((ReactContext) getContext());
      mMarkdownUtils.setMarkdownStyle(mMarkdownStyle);
      mMarkdownUtils.setParserId(mParserId);
      mReactEditText = (ReactEditText) child;
      mTextWatcher = new MarkdownTextWatcher(mMarkdownUtils);
      mReactEditText.addTextChangedListener(mTextWatcher);
      ensureClipboardCallback();
      // Re-assert after the attach cycle in case RN installs its own callback later.
      mReactEditText.post(this::ensureClipboardCallback);
      // Pin scroll to 0 while below the cap, undoing RN's forced scroll-to-caret.
      mReactEditText.setOnScrollChangeListener((v, scrollX, scrollY, oldX, oldY) -> pinScrollIfBelowCap(scrollY));
      applyNewStyles();
    }
  }

  @Override
  protected void onDetachedFromWindow() {
    super.onDetachedFromWindow();
    if (mReactEditText != null) {
      mReactEditText.removeTextChangedListener(mTextWatcher);
      mReactEditText.setCustomSelectionActionModeCallback(mOriginalActionModeCallback);
      mReactEditText.setOnKeyListener(null);
      mReactEditText.setOnScrollChangeListener(null);
      mReactEditText = null;
      mTextWatcher = null;
      mMarkdownUtils = null;
      mOriginalActionModeCallback = null;
      mClipboardCallback = null;
    }
  }

  protected void setMarkdownStyle(MarkdownStyle markdownStyle) {
    mMarkdownStyle = markdownStyle;
    if (mMarkdownUtils != null) {
      mMarkdownUtils.setMarkdownStyle(mMarkdownStyle);
    }
    applyNewStyles();
  }

  protected void setParserId(int parserId) {
    mParserId = parserId;
    if (mMarkdownUtils != null) {
      mMarkdownUtils.setParserId(mParserId);
    }
    applyNewStyles();
  }

  protected void setMaxScrollHeight(float dp) {
    mMaxScrollHeightPx = dp > 0 ? PixelUtil.toPixelFromDIP(dp) : 0;
  }

  // RN forces a scroll-to-caret on text change before the field's frame grows,
  // shifting the text up a line for a frame. While the content still fits under
  // the cap the field isn't meant to scroll, so undo it immediately. At the cap
  // (content taller than the cap) we leave scrolling alone.
  private void pinScrollIfBelowCap(int scrollY) {
    if (mReactEditText == null || mMaxScrollHeightPx <= 0 || scrollY == 0) {
      return;
    }
    Layout layout = mReactEditText.getLayout();
    if (layout == null) {
      return;
    }
    int contentHeight = layout.getHeight() + mReactEditText.getPaddingTop() + mReactEditText.getPaddingBottom();
    if (contentHeight <= mMaxScrollHeightPx) {
      mReactEditText.scrollTo(0, 0);
    }
  }

  protected void applyNewStyles() {
    if (mReactEditText != null && mMarkdownUtils != null) {
      ensureClipboardCallback();
      Editable editable = mReactEditText.getText();
      if (editable instanceof SpannableStringBuilder ssb) {
        mMarkdownUtils.applyMarkdownFormatting(ssb);
      }
    }
  }

  // NovelAI fork: make Copy/Cut emit chip copy text. Re-asserted on each style
  // pass because RN may install its own selection callback after we attach;
  // guarded so we don't wrap our own callback.
  private void ensureClipboardCallback() {
    if (mReactEditText == null) {
      return;
    }
    ActionMode.Callback current = mReactEditText.getCustomSelectionActionModeCallback();
    if (current instanceof MarkdownClipboardActionModeCallback) {
      return;
    }
    mOriginalActionModeCallback = current;
    mClipboardCallback = new MarkdownClipboardActionModeCallback(mReactEditText, current);
    mReactEditText.setCustomSelectionActionModeCallback(mClipboardCallback);

    // Hardware keyboard Ctrl+C/Ctrl+X bypass the selection ActionMode, so handle
    // them here too. RN doesn't use View.OnKeyListener, so this is safe.
    mReactEditText.setOnKeyListener((v, keyCode, event) -> {
      if (event.getAction() == KeyEvent.ACTION_DOWN && event.isCtrlPressed() && mClipboardCallback != null) {
        if (keyCode == KeyEvent.KEYCODE_C) {
          return mClipboardCallback.handleClipboard(false);
        }
        if (keyCode == KeyEvent.KEYCODE_X) {
          return mClipboardCallback.handleClipboard(true);
        }
      }
      return false;
    });
  }
}
