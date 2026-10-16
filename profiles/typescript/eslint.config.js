// Code Quality Standard - JS/TS profile (shared ESLint flat config).
//
// This is the single source of the JS/TS threshold numbers; every value traces
// to /core/THRESHOLDS.md. Consumers re-export this config from their own
// eslint.config.js. Do not restate these numbers elsewhere.
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import sonarjs from 'eslint-plugin-sonarjs';

export default tseslint.config(
  { ignores: ['dist/**', 'coverage/**'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    plugins: { sonarjs },
    rules: {
      // T1 Method / function length
      'max-lines-per-function': ['error', { max: 30, skipBlankLines: true, skipComments: true }],
      // T2 Cyclomatic complexity
      complexity: ['error', { max: 10 }],
      // T3 Cognitive complexity (matches the C# Sonar concept)
      'sonarjs/cognitive-complexity': ['error', 15],
      // T4 Parameters
      'max-params': ['error', 4],
      // T5 File / module length
      'max-lines': ['error', { max: 400, skipBlankLines: true, skipComments: true }],
      // Error handling: no empty blocks, no swallowed errors.
      'no-empty': ['error', { allowEmptyCatch: false }],
    },
  },
);
