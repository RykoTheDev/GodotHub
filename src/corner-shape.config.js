import { createCornerShapePlugin } from 'tailwindcss-corner-shape/dist/v4.mjs'

export default createCornerShapePlugin({
  default: 'squircle',
  exclude: ['full'],
})
