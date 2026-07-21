import {
  IconBriefcase,
  IconHouse,
  IconUser,
  IconCode,
  IconGamepad,
  IconPalette,
  IconGraduationCap,
  IconRocket,
  IconFlask,
  IconHeart,
  IconDumbbell,
  IconBook,
} from '../components/Icons'

export const WORKSPACE_ICONS = {
  briefcase: IconBriefcase,
  house: IconHouse,
  user: IconUser,
  code: IconCode,
  gamepad: IconGamepad,
  palette: IconPalette,
  graduation_cap: IconGraduationCap,
  rocket: IconRocket,
  flask: IconFlask,
  heart: IconHeart,
  dumbbell: IconDumbbell,
  book: IconBook,
} as const

export type WorkspaceIconKey = keyof typeof WORKSPACE_ICONS

export const WORKSPACE_ICON_KEYS = Object.keys(
  WORKSPACE_ICONS,
) as WorkspaceIconKey[]

export function getWorkspaceIcon(key: string) {
  return WORKSPACE_ICONS[key as WorkspaceIconKey] ?? IconBriefcase
}

export const WORKSPACE_COLOR_PRESETS = [
  '#457ff2',
  '#5865f2',
  '#7983f5',
  '#23a55a',
  '#f0b132',
  '#eb459e',
  '#00a8fc',
  '#2dd4bf',
  '#a78bfa',
  '#f97316',
  '#84cc16',
  '#e11d48',
  '#0ea5e9',
  '#8b5cf6',
]
