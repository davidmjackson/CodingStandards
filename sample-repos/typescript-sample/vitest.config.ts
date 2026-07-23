import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/violations/**', '**/*.test.ts'],
      // T7 Coverage: fail below 80%.
      thresholds: { lines: 80, functions: 80, branches: 80, statements: 80 },
    },
  },
});
