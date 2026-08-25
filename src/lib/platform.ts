export const isMac = /Mac/i.test(navigator.userAgent)
export const isWindows = /Win/i.test(navigator.userAgent)
export const isLinux = !isMac && !isWindows
export const defaultCornerRadius = 12
