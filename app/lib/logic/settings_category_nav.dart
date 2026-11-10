String? _pendingCategory;

void setPendingSettingsCategory(String? category) {
  _pendingCategory = category;
}

String? consumePendingSettingsCategory() {
  final category = _pendingCategory;
  _pendingCategory = null;
  return category;
}
