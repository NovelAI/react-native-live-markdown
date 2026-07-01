package com.expensify.livemarkdown;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class MarkdownRange {
  private final @NonNull String mType;
  private final int mStart;
  private final int mEnd;
  private final int mLength;
  private final int mDepth;

  // NovelAI fork: per-range style for the 'highlight' type. Colors are ARGB
  // ints (alpha carries opacity); null when the parser range omitted them.
  private @Nullable Integer mColor;
  private @Nullable Integer mBackgroundColor;
  private float mBorderRadius;
  private @Nullable String mLabel;
  private @Nullable String mCopyText;
  private @Nullable Integer mBorderColor;
  private float mBorderWidth;
  private float mPaddingHorizontal;
  private float mFontScale;

  public MarkdownRange(@NonNull String type, int start, int length, int depth) {
    mType = type;
    mStart = start;
    mEnd = start + length;
    mLength = length;
    mDepth = depth;
  }

  public String getType() {
    return mType;
  }

  public int getStart() {
    return mStart;
  }

  public int getEnd() {
    return mEnd;
  }

  public int getLength() {
    return mLength;
  }

  public int getDepth() {
    return mDepth;
  }

  // NovelAI fork: per-range 'highlight' style accessors.
  public void setColor(@Nullable Integer color) {
    mColor = color;
  }

  public @Nullable Integer getColor() {
    return mColor;
  }

  public void setBackgroundColor(@Nullable Integer backgroundColor) {
    mBackgroundColor = backgroundColor;
  }

  public @Nullable Integer getBackgroundColor() {
    return mBackgroundColor;
  }

  public void setBorderRadius(float borderRadius) {
    mBorderRadius = borderRadius;
  }

  public float getBorderRadius() {
    return mBorderRadius;
  }

  public void setLabel(@Nullable String label) {
    mLabel = label;
  }

  public @Nullable String getLabel() {
    return mLabel;
  }

  public void setCopyText(@Nullable String copyText) {
    mCopyText = copyText;
  }

  public @Nullable String getCopyText() {
    return mCopyText;
  }

  public void setBorderColor(@Nullable Integer borderColor) {
    mBorderColor = borderColor;
  }

  public @Nullable Integer getBorderColor() {
    return mBorderColor;
  }

  public void setBorderWidth(float borderWidth) {
    mBorderWidth = borderWidth;
  }

  public float getBorderWidth() {
    return mBorderWidth;
  }

  public void setPaddingHorizontal(float paddingHorizontal) {
    mPaddingHorizontal = paddingHorizontal;
  }

  public float getPaddingHorizontal() {
    return mPaddingHorizontal;
  }

  public void setFontScale(float fontScale) {
    mFontScale = fontScale;
  }

  public float getFontScale() {
    return mFontScale;
  }
}
