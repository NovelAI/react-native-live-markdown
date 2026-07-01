import {codegenNativeComponent} from 'react-native';
import type {ColorValue, ViewProps} from 'react-native';

import type {Float, Int32} from 'react-native/Libraries/Types/CodegenTypes';

interface CodeBlockStyle {
  fontFamily: string;
  fontSize: Float;
  color: ColorValue;
  backgroundColor: ColorValue;
  borderColor?: ColorValue;
  borderWidth?: Float;
  borderRadius?: Float;
  borderStyle?: string;
  padding?: Float;
  paddingVertical?: Float;
  paddingHorizontal?: Float;
}

interface MarkdownStyle {
  syntax: {
    color: ColorValue;
  };
  emoji: {
    fontSize: Float;
    fontFamily: string;
  };
  link: {
    color: ColorValue;
  };
  h1: {
    fontSize: Float;
  };
  blockquote: {
    borderColor: ColorValue;
    borderWidth: Float;
    marginLeft: Float;
    paddingLeft: Float;
  };
  code: CodeBlockStyle & {
    h1NestedFontSize?: Float;
  };
  pre: CodeBlockStyle;
  mentionHere: {
    color: ColorValue;
    backgroundColor: ColorValue;
    borderRadius?: Float;
  };
  mentionUser: {
    color: ColorValue;
    backgroundColor: ColorValue;
    borderRadius?: Float;
  };
  mentionReport: {
    color: ColorValue;
    backgroundColor: ColorValue;
    borderRadius?: Float;
  };
  inlineImage: {
    minWidth: Float;
    minHeight: Float;
    maxWidth: Float;
    maxHeight: Float;
    marginTop: Float;
    marginBottom: Float;
    borderRadius: Float;
  };
  loadingIndicatorContainer?: {
    backgroundColor?: ColorValue;
    borderWidth?: Float;
    borderColor?: ColorValue;
    borderRadius?: Float;
    width?: Float;
    height?: Float;
  };
  loadingIndicator?: {
    primaryColor?: ColorValue;
    secondaryColor?: ColorValue;
    width?: Float;
    height?: Float;
    borderWidth?: Float;
  };
}

interface NativeProps extends ViewProps {
  markdownStyle: MarkdownStyle;
  parserId: Int32;
  // NovelAI fork: when > 0, the height cap (dp) below which the field shouldn't
  // scroll. Android pins the EditText's scroll to 0 while content fits under it,
  // suppressing RN's forced scroll-to-caret jump on grow. iOS ignores it.
  maxScrollHeight?: Float;
}

export default codegenNativeComponent<NativeProps>('MarkdownTextInputDecoratorView', {
  interfaceOnly: true,
});

export type {MarkdownStyle};
