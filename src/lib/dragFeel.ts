export const DRAG_FEEL = {
  activationDistance: 7,

  ghostOpacity: 0.22,

  dropLine: {
    height: 2,
    dot: 4,
    glow: false,
  },

  autoScroll: {
    thresholdX: 0.12,
    thresholdY: 0.12,
    acceleration: 10,
  },
} as const

export const AUTO_SCROLL_CONFIG = {
  threshold: {
    x: DRAG_FEEL.autoScroll.thresholdX,
    y: DRAG_FEEL.autoScroll.thresholdY,
  },
  acceleration: DRAG_FEEL.autoScroll.acceleration,
}
