export const DRAG_FEEL = {
  activationDistance: 4,

  reflow: {
    duration: 220,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  },

  drop: {
    duration: 180,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  },

  tilt: {
    maxDeg: 2.5,
    velocityScale: 150,
    damping: 0.28,
    sampleMs: 16,
    easeMs: 90,
  },

  ghostOpacity: 0.45,

  dropLine: {
    height: 3,
    dot: 6,
    glow: true,
    transition: 150,
  },

  lift: {
    scale: 1.02,
  },

  autoScroll: {
    thresholdX: 0.2,
    thresholdY: 0.2,
    acceleration: 24,
  },
} as const

export const REFLOW_TRANSITION = `transform ${DRAG_FEEL.reflow.duration}ms ${DRAG_FEEL.reflow.easing}`

export const AUTO_SCROLL_CONFIG = {
  threshold: {
    x: DRAG_FEEL.autoScroll.thresholdX,
    y: DRAG_FEEL.autoScroll.thresholdY,
  },
  acceleration: DRAG_FEEL.autoScroll.acceleration,
}
