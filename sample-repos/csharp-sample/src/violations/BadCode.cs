namespace Sample;

// Deliberately violates the standard. Compiled only when IncludeViolations=true.
// Each member breaches a specific threshold from /core/THRESHOLDS.md.
public sealed class BadCode
{
    // T4: too many parameters (>4) -> Sonar S107
    public int TooManyParameters(int a, int b, int c, int d, int e, int f)
    {
        return a + b + c + d + e + f;
    }

    // T1/T2/T3: oversized method (>30 lines), high cyclomatic and cognitive
    // complexity -> Sonar S138 / S1541 / S3776
    public string Classify(int n)
    {
        var result = string.Empty;
        if (n > 100)
        {
            result += "big";
        }
        else
        {
            result += "small";
        }

        if (n % 2 == 0)
        {
            result += "even";
        }
        else
        {
            result += "odd";
        }

        if (n % 3 == 0)
        {
            result += "three";
        }

        if (n % 5 == 0)
        {
            result += "five";
        }

        if (n % 7 == 0)
        {
            result += "seven";
        }

        if (n % 11 == 0)
        {
            result += "eleven";
        }

        if (n < 0)
        {
            result += "neg";
        }

        if (n == 0)
        {
            result += "zero";
        }

        for (var i = 0; i < n; i++)
        {
            if (i % 2 == 0)
            {
                if (i % 4 == 0)
                {
                    if (i % 8 == 0)
                    {
                        result += "octo";
                    }
                }
            }
        }

        return result;
    }

    // T6: duplicated block (identical to DuplicateB) -> jscpd
    public int DuplicateA(int[] xs)
    {
        var total = 0;
        foreach (var x in xs)
        {
            if (x > 0) { total += x; } else { total -= x; }
            total = (total * 2) - 1;
        }
        return total;
    }

    public int DuplicateB(int[] xs)
    {
        var total = 0;
        foreach (var x in xs)
        {
            if (x > 0) { total += x; } else { total -= x; }
            total = (total * 2) - 1;
        }
        return total;
    }
}
