import {MarkdownTextInput} from '../src';
import type {MarkdownRange} from '../src';

global.jsi_setMarkdownRuntime = jest.fn();
global.jsi_registerMarkdownWorklet = jest.fn();
global.jsi_unregisterMarkdownWorklet = jest.fn();

// NovelAI fork: no-op parser mock; the fork ships its own parser worklet.
const parserMock = (): MarkdownRange[] => {
  'worklet';

  return [];
};

const getWorkletRuntimeMock = () => ({});

export {MarkdownTextInput, parserMock as parseExpensiMark, getWorkletRuntimeMock as getWorkletRuntime};
