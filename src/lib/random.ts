export function randomHex(): string {
  return (
    '#' +
    Math.floor(Math.random() * 0x1000000)
      .toString(16)
      .padStart(6, '0')
  )
}

export function randomConstrainedHex(minSum: number, maxSum: number): string {
  for (let i = 0; i < 100; i++) {
    const hex = randomHex()
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    const sum = r + g + b
    if (sum >= minSum && sum <= maxSum) return hex
  }
  return '#808080'
}
