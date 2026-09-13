/**
 * Every value that shapes how dragging feels, in one place.
 *
 * The Projects surfaces (list, grid, kanban) all read from here, so a tweak is
 * never applied to one view and forgotten in the others. Times are in
 * milliseconds, distances in pixels, angles in degrees.
 */
export const DRAG_FEEL = {
  /** Pointer travel before a press becomes a drag. Smaller = eager, larger = deliberate. */
  activationDistance: 4,

  /** Siblings sliding into the gap while a card is airborne. */
  reflow: {
    duration: 220,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  },

  /** The floating card settling into its slot on drop. */
  drop: {
    duration: 180,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  },

  /** Velocity-driven lean of the floating card. */
  tilt: {
    /** Hard cap so the card never looks like it fell over. */
    maxDeg: 2.5,
    /** Degrees per (px/ms). Higher leans more for the same flick. */
    velocityScale: 150,
    /** 0..1 per sample. Higher follows the pointer more tightly, lower is silkier. */
    damping: 0.28,
    /** Ignore samples closer together than this to avoid jitter. */
    sampleMs: 16,
    /** CSS ease applied between samples. 0 disables. */
    easeMs: 90,
  },

  /** The ghost left behind while a card is airborne. */
  ghostOpacity: 0.45,

  /** The accent insertion line. */
  dropLine: {
    height: 3,
    dot: 6,
    glow: true,
    transition: 150,
  },

  /** How high the floating card is lifted. */
  lift: {
    scale: 1.02,
  },

  /** Viewport-edge auto scroll while dragging. */
  autoScroll: {
    thresholdX: 0.2,
    thresholdY: 0.2,
    acceleration: 24,
  },
} as const

/** dnd-kit transition string for the sibling reflow. */
export const REFLOW_TRANSITION = `transform ${DRAG_FEEL.reflow.duration}ms ${DRAG_FEEL.reflow.easing}`

/** dnd-kit `autoScroll` option built from the tuning values above. */
export const AUTO_SCROLL_CONFIG = {
  threshold: {
    x: DRAG_FEEL.autoScroll.thresholdX,
    y: DRAG_FEEL.autoScroll.thresholdY,
  },
  acceleration: DRAG_FEEL.autoScroll.acceleration,
}
