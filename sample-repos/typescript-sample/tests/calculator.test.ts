import { describe, expect, it } from 'vitest';

import { add, divide, multiply, subtract } from '../src/calculator';

describe('calculator', () => {
  it('adds', () => {
    expect(add(2, 3)).toBe(5);
  });

  it('subtracts', () => {
    expect(subtract(3, 2)).toBe(1);
  });

  it('multiplies', () => {
    expect(multiply(2, 3)).toBe(6);
  });

  it('divides', () => {
    expect(divide(8, 2)).toBe(4);
  });

  it('rejects division by zero', () => {
    expect(() => divide(1, 0)).toThrow('Cannot divide by zero.');
  });
});
