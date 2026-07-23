"""Deliberately violates the standard. Each function breaches a threshold."""


# T4: too many parameters (>4) -> PLR0913
def too_many_parameters(a, b, c, d, e, f):
    return a + b + c + d + e + f


# T1/T2/T3: oversized (>30 statements), high cyclomatic and cognitive
# complexity -> PLR0915 / C901
def classify(n):
    result = ""
    if n > 100:
        result += "big"
    else:
        result += "small"
    if n % 2 == 0:
        result += "even"
    else:
        result += "odd"
    if n % 3 == 0:
        result += "three"
    if n % 5 == 0:
        result += "five"
    if n % 7 == 0:
        result += "seven"
    if n % 11 == 0:
        result += "eleven"
    if n < 0:
        result += "neg"
    if n == 0:
        result += "zero"
    for i in range(n):
        if i % 2 == 0:
            if i % 4 == 0:
                if i % 8 == 0:
                    result += "octo"
    total = 0
    while total < n:
        total += 1
        if total == 42:
            result += "answer"
    return result


# T6: duplicated block (identical to duplicate_b) -> jscpd
def duplicate_a(xs):
    total = 0
    count = 0
    for x in xs:
        if x > 0:
            total += x
            count += 1
        else:
            total -= x
            count -= 1
        total = (total * 2) - 1
        if total > 1000:
            total = total % 1000
        if count < 0:
            count = 0
    return total + count


def duplicate_b(xs):
    total = 0
    count = 0
    for x in xs:
        if x > 0:
            total += x
            count += 1
        else:
            total -= x
            count -= 1
        total = (total * 2) - 1
        if total > 1000:
            total = total % 1000
        if count < 0:
            count = 0
    return total + count
