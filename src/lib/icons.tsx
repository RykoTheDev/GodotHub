import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { motion, useReducedMotion, type TargetAndTransition } from 'framer-motion'
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core'
import { useEffect, useRef, useState } from 'react'
import {
  faGithub as faGithubBrand,
  faGitlab as faGitlabBrand,
} from '@fortawesome/free-brands-svg-icons'
import {
  faFolderPlus,
  faFileImport,
  faPlay,
  faTrash,
  faDownload,
  faDiagramProject,
  faChevronUp,
  faChevronDown,
  faChevronLeft,
  faChevronRight,
  faXmark,
  faGear,
  faPlus,
  faGripVertical,
  faTableCellsLarge,
  faListUl,
  faLanguage,
  faSun,
  faMoon,
  faPen,
  faCheck,
  faCheckCircle,
  faTriangleExclamation,
  faInfoCircle,
  faBomb,
  faClock,
  faCopy,
  faEllipsisVertical,
  faMagnifyingGlass,
  faFilter,
  faSort,
  faTags,
  faFolder,
  faNewspaper,
  faAnglesLeft,
  faAnglesRight,
  faArrowDown,
  faArrowUp,
  faArrowUpRightFromSquare,
  faArrowRotateRight,
  faWifi,
  faMapPin,
  faBriefcase,
  faHouse,
  faPause,
  faUser,
  faCode,
  faCodeBranch,
  faTerminal,
  faCloudArrowDown,
  faHistory,
  faGamepad,
  faPalette,
  faGraduationCap,
  faRocket,
  faFlask,
  faHeart,
  faDumbbell,
  faBook,
  faBookOpen,
  faBug,
  faHardDrive,
  faBell,
  faSpinner,
  faCircleCheck,
  faCircleXmark,
  faStar,
  faStore,
  faStopwatch,
  faFont,
  faDesktop,
  faUniversalAccess,
  faMinus,
  faSquare,
  faClone,
  faWindowMaximize,
  faWindowRestore,
  faPlug,
  faTableColumns,
  faEye,
  faEyeSlash,
} from '@fortawesome/free-solid-svg-icons'

export interface IconProps extends Omit<React.SVGProps<SVGSVGElement>, 'ref'> {
  fill?: string
}

interface IconMotion {
  whileHover?: TargetAndTransition
  whileTap?: TargetAndTransition
}

const M = {
  pop: { whileHover: { scale: 1.18 }, whileTap: { scale: 0.86 } },
  press: { whileHover: { scale: 1.12 }, whileTap: { scale: 0.82 } },
  spin: {
    whileHover: { rotate: 360, transition: { duration: 0.7, ease: 'easeInOut' } },
    whileTap: { scale: 0.9, transition: { duration: 0.12 } },
  },
  spinBack: {
    whileHover: { rotate: -360, transition: { duration: 0.7, ease: 'easeInOut' } },
    whileTap: { scale: 0.9, transition: { duration: 0.12 } },
  },
  wiggle: {
    whileHover: { rotate: [0, -13, 11, -7, 5, 0], transition: { duration: 0.55 } },
    whileTap: { scale: 0.9 },
  },
  beat: {
    whileHover: { scale: [1, 1.25, 1, 1.2, 1], transition: { duration: 0.6 } },
    whileTap: { scale: 0.9 },
  },
  bobDown: {
    whileHover: { y: [0, 2.5, 0], transition: { duration: 0.7, repeat: Infinity } },
    whileTap: { scale: 0.9 },
  },
  nudgeUp: { whileHover: { y: -2.5 }, whileTap: { scale: 0.85 } },
  nudgeDown: { whileHover: { y: 2.5 }, whileTap: { scale: 0.85 } },
  nudgeLeft: { whileHover: { x: -2.5 }, whileTap: { scale: 0.85 } },
  nudgeRight: { whileHover: { x: 2.5 }, whileTap: { scale: 0.85 } },
  nudgeUpRight: { whileHover: { x: 2, y: -2 }, whileTap: { scale: 0.85 } },
  rotate90: { whileHover: { rotate: 90, scale: 1.1 }, whileTap: { scale: 0.85 } },
  swivel: {
    whileHover: { rotate: [0, -8, 8, 0], transition: { duration: 0.5 } },
    whileTap: { scale: 0.9 },
  },
  lift: { whileHover: { y: -3, rotate: -10, scale: 1.1 }, whileTap: { scale: 0.9 } },
} satisfies Record<string, IconMotion>

const REST = { scale: 1, rotate: 0, x: 0, y: 0 }

function solid(icon: IconDefinition, preset: IconMotion = M.pop) {
  return ({ className, fill, style }: IconProps) => {
    const reduce = useReducedMotion()
    const ref = useRef<HTMLSpanElement>(null)
    const [active, setActive] = useState(false)
    useEffect(() => {
      ref.current?.removeAttribute('tabindex')
    }, [reduce])
    useEffect(() => {
      const el = ref.current
      if (!el) return
      const host =
        (el.closest('button, a, [role="button"]') as HTMLElement | null) ?? el
      const enter = () => setActive(true)
      const leave = () => setActive(false)
      host.addEventListener('mouseenter', enter)
      host.addEventListener('mouseleave', leave)
      return () => {
        host.removeEventListener('mouseenter', enter)
        host.removeEventListener('mouseleave', leave)
      }
    }, [])
    const fa = (
      <FontAwesomeIcon
        icon={icon}
        className={className}
        style={fill === 'none' ? { opacity: 0.45, ...style } : style}
      />
    )
    if (reduce) return fa
    return (
      <motion.span
        ref={ref}
        style={{
          display: 'inline-flex',
          flexShrink: 0,
          lineHeight: 0,
          verticalAlign: '-0.125em',
        }}
        initial={false}
        animate={active ? 'active' : 'rest'}
        variants={{ rest: REST, active: preset.whileHover ?? {} }}
        whileTap={preset.whileTap}
      >
        {fa}
      </motion.span>
    )
  }
}

export const IconFolderPlus = solid(faFolderPlus)
export const IconImport = solid(faFileImport, M.bobDown)
export const IconPause = solid(faPause, M.press)
export const IconPlay = solid(faPlay, M.press)
export const IconTrash = solid(faTrash, M.wiggle)
export const IconDownload = solid(faDownload, M.bobDown)
export const IconNode = solid(faDiagramProject)
export const IconChevronUp = solid(faChevronUp, M.nudgeUp)
export const IconChevronDown = solid(faChevronDown, M.nudgeDown)
export const IconChevronLeft = solid(faChevronLeft, M.nudgeLeft)
export const IconChevronRight = solid(faChevronRight, M.nudgeRight)
export const IconX = solid(faXmark, M.rotate90)
export const IconGear = solid(faGear, M.spin)
export const IconPlus = solid(faPlus, M.rotate90)
export const IconPin = solid(faMapPin, M.swivel)
export const IconGrip = solid(faGripVertical)
export const IconLayoutGrid = solid(faTableCellsLarge)
export const IconLayoutList = solid(faListUl)
export const IconKanban = solid(faTableColumns)
export const IconLanguage = solid(faLanguage, M.swivel)
export const IconSun = solid(faSun, M.spin)
export const IconMoon = solid(faMoon, M.swivel)
export const IconPencil = solid(faPen, M.swivel)
export const IconCheck = solid(faCheck)
export const IconClock = solid(faClock, M.spin)
export const IconSearch = solid(faMagnifyingGlass, M.swivel)
export const IconFilter = solid(faFilter)
export const IconArrowUpDown = solid(faSort)
export const IconTags = solid(faTags, M.swivel)
export const IconNews = solid(faNewspaper)
export const IconChevronsLeft = solid(faAnglesLeft, M.nudgeLeft)
export const IconChevronsRight = solid(faAnglesRight, M.nudgeRight)
export const IconArrowDown = solid(faArrowDown, M.nudgeDown)
export const IconArrowUp = solid(faArrowUp, M.nudgeUp)
export const IconExternalLink = solid(faArrowUpRightFromSquare, M.nudgeUpRight)
export const IconRefresh = solid(faArrowRotateRight, M.spin)
export const IconWifiOff = solid(faWifi)
export const IconBriefcase = solid(faBriefcase)
export const IconHouse = solid(faHouse)
export const IconUser = solid(faUser)
export const IconUniversalAccess = solid(faUniversalAccess)
export const IconCode = solid(faCode)
export const IconGitBranch = solid(faCodeBranch, M.swivel)
export const IconTerminal = solid(faTerminal)
export const IconCloudArrowDown = solid(faCloudArrowDown, M.bobDown)
export const IconHistory = solid(faHistory, M.spinBack)
export const IconGamepad = solid(faGamepad, M.wiggle)
export const IconPalette = solid(faPalette, M.swivel)
export const IconGraduationCap = solid(faGraduationCap, M.swivel)
export const IconRocket = solid(faRocket, M.lift)
export const IconFlask = solid(faFlask, M.wiggle)
export const IconHeart = solid(faHeart, M.beat)
export const IconDumbbell = solid(faDumbbell, M.wiggle)
export const IconBook = solid(faBook)
export const IconBookOpen = solid(faBookOpen)
export const IconBug = solid(faBug, M.wiggle)
export const IconHardDrive = solid(faHardDrive)
export const IconCheckCircle = solid(faCheckCircle)
export const IconAlertTriangle = solid(faTriangleExclamation, M.wiggle)
export const IconInfo = solid(faInfoCircle)
export const IconBomb = solid(faBomb, M.wiggle)
export const IconCopy = solid(faCopy)
export const IconMore = solid(faEllipsisVertical)
export const IconBell = solid(faBell, M.wiggle)
export const IconSpinner = solid(faSpinner)
export const IconCircleCheck = solid(faCircleCheck)
export const IconCircleX = solid(faCircleXmark, M.rotate90)
export const IconStar = solid(faStar, M.beat)
export const IconStore = solid(faStore)
export const IconStopwatch = solid(faStopwatch, M.spin)
export const IconType = solid(faFont)
export const IconMonitor = solid(faDesktop)
export const IconFolder = solid(faFolder)
export const IconMinus = solid(faMinus)
export const IconSquare = solid(faSquare)
export const IconWindowMaximize = solid(faWindowMaximize)
export const IconWindowRestore = solid(faWindowRestore)
export const IconClone = solid(faClone)
export const IconPlug = solid(faPlug, M.swivel)
export const IconEye = solid(faEye)
export const IconEyeSlash = solid(faEyeSlash)
export const IconGithub = solid(faGithubBrand as IconDefinition)
export const IconGitlab = solid(faGitlabBrand as IconDefinition)
