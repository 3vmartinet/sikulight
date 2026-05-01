from engine.src.models.task import StandardAction

def test_standard_action_enum():
    assert StandardAction.MIDDLE_CLICK.value == "MIDDLE_CLICK"
    assert StandardAction.SCROLL.value == "SCROLL"
    assert len(StandardAction) == 6
