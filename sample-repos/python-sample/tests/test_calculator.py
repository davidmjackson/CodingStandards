"""Behaviour tests for the clean reference code."""

import pytest

from calculator import add, divide, multiply, subtract


def test_add_returns_sum():
    assert add(2, 3) == 5


def test_subtract_returns_difference():
    assert subtract(3, 2) == 1


def test_multiply_returns_product():
    assert multiply(2, 3) == 6


def test_divide_returns_quotient():
    assert divide(8, 2) == 4


def test_divide_by_zero_raises():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)
