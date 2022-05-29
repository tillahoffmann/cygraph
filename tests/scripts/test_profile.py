from cygraph.scripts import profile


def test_profile():
    durations = profile.__main__(["--max_duration=0.1", "100"])
    assert isinstance(durations, dict)
