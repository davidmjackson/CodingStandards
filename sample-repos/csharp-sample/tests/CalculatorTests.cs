using Sample;
using Xunit;

namespace Sample.Tests;

public sealed class CalculatorTests
{
    [Fact]
    public void Add_ReturnsSum() => Assert.Equal(5, Calculator.Add(2, 3));

    [Fact]
    public void Subtract_ReturnsDifference() => Assert.Equal(1, Calculator.Subtract(3, 2));

    [Fact]
    public void Multiply_ReturnsProduct() => Assert.Equal(6, Calculator.Multiply(2, 3));

    [Fact]
    public void Divide_ReturnsQuotient() => Assert.Equal(4, Calculator.Divide(8, 2));

    [Fact]
    public void Divide_ByZero_Throws() =>
        Assert.Throws<DivideByZeroException>(() => Calculator.Divide(1, 0));
}
