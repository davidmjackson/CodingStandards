"""Clean reference code. Meets every gated threshold."""


def add(a: int, b: int) -> int:
    return a + b


def subtract(a: int, b: int) -> int:
    return a - b


def multiply(a: int, b: int) -> int:
    return a * b


def divide(a: int, b: int) -> int:
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero.")
    return a // b
