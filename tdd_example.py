def normalize_todo_title(title: str, max_length: int = 80) -> str:
    normalized_title = title.strip()
    if not normalized_title:
        raise ValueError("Todo title cannot be empty.")
    if len(normalized_title) > max_length:
        raise ValueError(f"Todo title cannot exceed {max_length} characters.")
    return normalized_title
