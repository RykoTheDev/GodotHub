let openCount = 0

window.addEventListener('app:dropdown-open', () => {
  openCount += 1
})
window.addEventListener('app:dropdown-close', () => {
  openCount = Math.max(0, openCount - 1)
})

export function isPopupOpen(): boolean {
  return openCount > 0
}
