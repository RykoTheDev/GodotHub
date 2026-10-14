export const DRAG_FEEL = {
  activationDistance: 7,

  reflow: {
    duration: 200,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  },

  drop: {
    duration: 220,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  },

  tilt: {
    maxDeg: 1.2,
    velocityScale: 18,
    damping: 0.28,
    sampleMs: 16,
    easeMs: 90,
  },

  ghostOpacity: 0.22,

  dropLine: {
    height: 2,
    dot: 4,
    glow: false,
    transition: 150,
  },

  lift: {
    scale: 1.015,
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
