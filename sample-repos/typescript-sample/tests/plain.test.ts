import { createRequire } from 'node:module';
import path from 'node:path';

import { afterEach, describe, expect, it, vi } from 'vitest';

// src/plain is CommonJS, so it is loaded the way Node loads it.
const load = createRequire(import.meta.url);

describe('plain JavaScript', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('resolves a data file against the working directory', () => {
    const { resolveData } = load('../src/plain/commonjs.js');
    expect(resolveData('a.json')).toBe(path.join(process.cwd(), 'a.json'));
  });

  it('sets the page title on load', () => {
    const heading = { textContent: '' };
    vi.stubGlobal('document', { querySelector: () => heading });
    vi.stubGlobal('window', { scrollTo: vi.fn() });
    load('../src/plain/browser.js');
    expect(heading.textContent).toBe('Ready');
  });
});
