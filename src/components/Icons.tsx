import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core'
import {
  faFolderPlus,
  faFileImport,
  faPlay,
  faTrash,
  faDownload,
  faDiagramProject,
  faChevronUp,
  faChevronDown,
  faChevronRight,
  faXmark,
  faGear,
  faPlus,
  faGripVertical,
  faTableCellsLarge,
  faListUl,
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
  faNewspaper,
  faAnglesLeft,
  faAnglesRight,
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
} from '@fortawesome/free-solid-svg-icons'

interface IconProps extends Omit<React.SVGProps<SVGSVGElement>, 'ref'> {
  fill?: string
}

function solid(icon: IconDefinition) {
  return ({ className, fill, style }: IconProps) => (
    <FontAwesomeIcon
      icon={icon}
      className={className}
      style={fill === 'none' ? { opacity: 0.45, ...style } : style}
    />
  )
}

export const IconFolderPlus = solid(faFolderPlus)
export const IconImport = solid(faFileImport)
export const IconPause = solid(faPause)
export const IconPlay = solid(faPlay)
export const IconTrash = solid(faTrash)
export const IconDownload = solid(faDownload)
export const IconNode = solid(faDiagramProject)
export const IconChevronUp = solid(faChevronUp)
export const IconChevronDown = solid(faChevronDown)
export const IconChevronRight = solid(faChevronRight)
export const IconX = solid(faXmark)
export const IconGear = solid(faGear)
export const IconPlus = solid(faPlus)
export const IconPin = solid(faMapPin)
export const IconGrip = solid(faGripVertical)
export const IconLayoutGrid = solid(faTableCellsLarge)
export const IconLayoutList = solid(faListUl)
export const IconSun = solid(faSun)
export const IconMoon = solid(faMoon)
export const IconPencil = solid(faPen)
export const IconCheck = solid(faCheck)
export const IconClock = solid(faClock)
export const IconSearch = solid(faMagnifyingGlass)
export const IconFilter = solid(faFilter)
export const IconArrowUpDown = solid(faSort)
export const IconTags = solid(faTags)
export const IconNews = solid(faNewspaper)
export const IconChevronsLeft = solid(faAnglesLeft)
export const IconChevronsRight = solid(faAnglesRight)
export const IconExternalLink = solid(faArrowUpRightFromSquare)
export const IconRefresh = solid(faArrowRotateRight)
export const IconWifiOff = solid(faWifi)
export const IconBriefcase = solid(faBriefcase)
export const IconHouse = solid(faHouse)
export const IconUser = solid(faUser)
export const IconCode = solid(faCode)
export const IconGitBranch = solid(faCodeBranch)
export const IconTerminal = solid(faTerminal)
export const IconCloudArrowDown = solid(faCloudArrowDown)
export const IconHistory = solid(faHistory)
export const IconGamepad = solid(faGamepad)
export const IconPalette = solid(faPalette)
export const IconGraduationCap = solid(faGraduationCap)
export const IconRocket = solid(faRocket)
export const IconFlask = solid(faFlask)
export const IconHeart = solid(faHeart)
export const IconDumbbell = solid(faDumbbell)
export const IconBook = solid(faBook)
export const IconBookOpen = solid(faBookOpen)
export const IconBug = solid(faBug)
export const IconHardDrive = solid(faHardDrive)
export const IconCheckCircle = solid(faCheckCircle)
export const IconAlertTriangle = solid(faTriangleExclamation)
export const IconInfo = solid(faInfoCircle)
export const IconBomb = solid(faBomb)
export const IconCopy = solid(faCopy)
export const IconMore = solid(faEllipsisVertical)
export const IconBell = solid(faBell)
export const IconSpinner = solid(faSpinner)
export const IconCircleCheck = solid(faCircleCheck)
export const IconCircleX = solid(faCircleXmark)
