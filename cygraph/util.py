import numbers


def assert_interval(name: str, value: numbers.Number, low: numbers.Number, high: numbers.Number,
                    inclusive_low: bool = True, inclusive_high: bool = True) -> None:
    """
    Assert that a value falls in a certain interval and raise a `ValueError` if not.

    Args:
        name: Name of the variable for the error message.
        value: Value to check.
        low: Lower limit of the interval.
        high: Upper limit of the interval.
        inclusive_left: Whether the lower limit of the interval is inclusive.
        inclusive_right: Whether the upper limit of the interval is inclusive.

    Raises:
        ValueError: If the value does not fall in the interval.
    """
    outside = (
        low is not None
        and ((value < low and inclusive_low) or (value <= low and not inclusive_low))
    ) or (
        high is not None
        and ((value > high) and inclusive_high or (value >= high and not inclusive_high))
    )
    if outside:
        raise ValueError(f"{name} must belong to the interval {'[' if inclusive_low else '('}"
                         f"{'-inf' if low is None else low}, {'inf' if high is None else high}"
                         f"{']' if inclusive_high else ')'} but got {value}")
