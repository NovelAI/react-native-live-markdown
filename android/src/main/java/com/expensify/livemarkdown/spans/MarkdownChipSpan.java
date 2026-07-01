package com.expensify.livemarkdown.spans;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.text.TextPaint;
import android.text.style.ReplacementSpan;

import androidx.annotation.ColorInt;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.uimanager.PixelUtil;

/**
 * NovelAI fork: draws a `chip` range's single sentinel as a rounded pill
 * containing `label` (subtle fill + a border in the macro colour), visually
 * replacing the underlying U+FFFC. Sized to the label, so it reads as an atomic
 * token. Visual metrics arrive from JS in dp and are converted to px here, so
 * chips render at the same physical size as on iOS (which uses points).
 */
public class MarkdownChipSpan extends ReplacementSpan implements MarkdownSpan {
  private final @NonNull String mLabel;
  private final @NonNull String mCopyText;
  private final @Nullable Integer mTextColor;
  private final @Nullable Integer mBackgroundColor;
  private final @Nullable Integer mBorderColor;
  private final float mBorderWidth;
  private final float mBorderRadius;
  private final float mPaddingHorizontal;
  private final float mFontScale;

  public MarkdownChipSpan(
      @NonNull String label,
      @NonNull String copyText,
      @Nullable Integer textColor,
      @Nullable Integer backgroundColor,
      @Nullable Integer borderColor,
      float borderWidthDip,
      float borderRadiusDip,
      float paddingHorizontalDip,
      float fontScale) {
    mLabel = label;
    mCopyText = copyText;
    mTextColor = textColor;
    mBackgroundColor = backgroundColor;
    mBorderColor = borderColor;
    mBorderWidth = PixelUtil.toPixelFromDIP(borderWidthDip);
    mBorderRadius = PixelUtil.toPixelFromDIP(borderRadiusDip);
    mPaddingHorizontal = PixelUtil.toPixelFromDIP(paddingHorizontalDip);
    mFontScale = fontScale > 0 ? fontScale : 1f;
  }

  public @NonNull String getCopyText() {
    return mCopyText;
  }

  private TextPaint chipPaint(@NonNull Paint base) {
    TextPaint paint = new TextPaint(base);
    paint.setTextSize(base.getTextSize() * mFontScale);
    return paint;
  }

  @Override
  public int getSize(@NonNull Paint paint, CharSequence text, int start, int end, @Nullable Paint.FontMetricsInt fm) {
    if (fm != null) {
      // Keep the surrounding line metrics so line height doesn't jump.
      Paint.FontMetricsInt pfm = paint.getFontMetricsInt();
      fm.ascent = pfm.ascent;
      fm.descent = pfm.descent;
      fm.top = pfm.top;
      fm.bottom = pfm.bottom;
    }
    float inset = mBorderColor != null ? mBorderWidth : 0;
    return Math.round(chipPaint(paint).measureText(mLabel) + (mPaddingHorizontal + inset) * 2);
  }

  @Override
  public void draw(@NonNull Canvas canvas, CharSequence text, int start, int end, float x, int top, int y, int bottom, @NonNull Paint paint) {
    TextPaint chipPaint = chipPaint(paint);
    float labelWidth = chipPaint.measureText(mLabel);
    float inset = mBorderColor != null ? mBorderWidth : 0;
    float width = labelWidth + (mPaddingHorizontal + inset) * 2;

    Paint.FontMetrics lineFm = paint.getFontMetrics();
    float lineCenter = y + (lineFm.ascent + lineFm.descent) / 2f;
    Paint.FontMetrics chipFm = chipPaint.getFontMetrics();
    float pillHeight = (chipFm.descent - chipFm.ascent) + inset * 2;
    float pillTop = lineCenter - pillHeight / 2f;

    RectF pill = new RectF(x, pillTop, x + width, pillTop + pillHeight);

    if (mBackgroundColor != null) {
      Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);
      fill.setStyle(Paint.Style.FILL);
      fill.setColor(mBackgroundColor);
      canvas.drawRoundRect(pill, mBorderRadius, mBorderRadius, fill);
    }
    if (mBorderColor != null && mBorderWidth > 0) {
      RectF stroke = new RectF(pill.left + inset / 2f, pill.top + inset / 2f, pill.right - inset / 2f, pill.bottom - inset / 2f);
      Paint border = new Paint(Paint.ANTI_ALIAS_FLAG);
      border.setStyle(Paint.Style.STROKE);
      border.setStrokeWidth(mBorderWidth);
      border.setColor(mBorderColor);
      canvas.drawRoundRect(stroke, mBorderRadius, mBorderRadius, border);
    }

    if (mTextColor != null) {
      chipPaint.setColor(mTextColor);
    } // else keep the editor's text colour (inherited from `paint`).
    float baseline = lineCenter - (chipFm.ascent + chipFm.descent) / 2f;
    canvas.drawText(mLabel, x + inset + mPaddingHorizontal, baseline, chipPaint);
  }
}
