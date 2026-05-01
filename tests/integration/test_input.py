import pytest
from engine.src.core.input import simulate_click

def test_simulate_click_validation():
    # Test valid middle click
    try:
        simulate_click(0, 0, button='middle')
    except Exception as e:
        pytest.fail(f"simulate_click failed on valid middle button: {e}")

    # Test invalid button
    with pytest.raises(ValueError):
        simulate_click(0, 0, button='invalid')
