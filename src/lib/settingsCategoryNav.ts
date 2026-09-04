let pendingCategory: string | null = null

export function setPendingSettingsCategory(cat: string | null) {
  pendingCategory = cat
}

export function consumePendingSettingsCategory(): string | null {
  const cat = pendingCategory
  pendingCategory = null
  return cat
}