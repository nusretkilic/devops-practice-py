import pytest

from tdd_example import normalize_todo_title


def test_normalize_todo_title_strips_surrounding_whitespace():
    assert normalize_todo_title("  Write tests  ") == "Write tests"


def test_normalize_todo_title_rejects_empty_title():
    with pytest.raises(ValueError, match="cannot be empty"):
        normalize_todo_title("   ")


def test_normalize_todo_title_rejects_title_over_maximum_length():
    with pytest.raises(ValueError, match="cannot exceed 10"):
        normalize_todo_title("A" * 11, max_length=10)
