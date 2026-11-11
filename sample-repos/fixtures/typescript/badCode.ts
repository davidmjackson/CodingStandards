// Deliberately violates the standard. Each function breaches a threshold.

// T4: too many parameters (>4) -> max-params
export function tooManyParameters(
  a: number,
  b: number,
  c: number,
  d: number,
  e: number,
  f: number,
): number {
  return a + b + c + d + e + f;
}

// T1/T2/T3: oversized (>30 lines), high cyclomatic and cognitive complexity
// -> max-lines-per-function / complexity / sonarjs/cognitive-complexity
export function classify(n: number): string {
  let result = '';
  if (n > 100) {
    result += 'big';
  } else {
    result += 'small';
  }
  if (n % 2 === 0) {
    result += 'even';
  } else {
    result += 'odd';
  }
  if (n % 3 === 0) {
    result += 'three';
  }
  if (n % 5 === 0) {
    result += 'five';
  }
  if (n % 7 === 0) {
    result += 'seven';
  }
  if (n % 11 === 0) {
    result += 'eleven';
  }
  if (n < 0) {
    result += 'neg';
  }
  if (n === 0) {
    result += 'zero';
  }
  for (let i = 0; i < n; i++) {
    if (i % 2 === 0) {
      if (i % 4 === 0) {
        if (i % 8 === 0) {
          result += 'octo';
        }
      }
    }
  }
  return result;
}

// T6: duplicated block (identical to duplicateB) -> jscpd
export function duplicateA(xs: number[]): number {
  let total = 0;
  for (const x of xs) {
    if (x > 0) {
      total += x;
    } else {
      total -= x;
    }
    total = total * 2 - 1;
  }
  return total;
}

export function duplicateB(xs: number[]): number {
  let total = 0;
  for (const x of xs) {
    if (x > 0) {
      total += x;
    } else {
      total -= x;
    }
    total = total * 2 - 1;
  }
  return total;
}
