import type { NamingConvention } from '../types'

function capitalizeWord(word: string): string {
  return word ? word.charAt(0).toUpperCase() + word.slice(1).toLowerCase() : word
}


function splitNamingWords(name: string): string[] {
  const words: string[] = []
  let current = ''
  for (let i = 0; i < name.length; i++) {
    const c = name[i]
    if (!/[a-zA-Z0-9]/.test(c)) {
      if (current) {
        words.push(current)
        current = ''
      }
      continue
    }
    if (current) {
      const last = current[current.length - 1]
      const next = name[i + 1]
      const split =
        ((/[a-z0-9]/.test(last) && /[A-Z]/.test(c)) ||
          (/[A-Z]/.test(last) &&
            /[A-Z]/.test(c) &&
            next !== undefined &&
            /[a-z]/.test(next)))
      if (split) {
        words.push(current)
        current = ''
      }
    }
    current += c
  }
  if (current) words.push(current)
  return words
}

export function applyNamingConvention(
  name: string,
  convention: NamingConvention,
): string {
  const words = splitNamingWords(name)
  if (words.length === 0) return name.trim()
  switch (convention) {
    case 'kebab-case':
      return words.map((w) => w.toLowerCase()).join('-')
    case 'snake_case':
      return words.map((w) => w.toLowerCase()).join('_')
    case 'camelCase':
      return words
        .map((w, i) => (i === 0 ? w.toLowerCase() : capitalizeWord(w)))
        .join('')
    case 'PascalCase':
      return words.map(capitalizeWord).join('')
    case 'Title Case':
      return words.map(capitalizeWord).join(' ')
    case 'keep':
    default:
      return name
  }
}
