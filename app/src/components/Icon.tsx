type IconProps = { size?: number; className?: string }

const base = (size: number) => ({
  width: size,
  height: size,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2.2,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
})

export const IconBack = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M15 5 8 12l7 7" />
  </svg>
)

export const IconForward = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="m9 5 7 7-7 7" />
  </svg>
)

export const IconGear = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <circle cx="12" cy="12" r="3.2" />
    <path d="M19.4 15a1.7 1.7 0 0 0 .34 1.87l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.7 1.7 0 0 0-1.87-.34 1.7 1.7 0 0 0-1 1.55V21a2 2 0 1 1-4 0v-.09a1.7 1.7 0 0 0-1.1-1.55 1.7 1.7 0 0 0-1.88.34l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.7 1.7 0 0 0 4.6 15a1.7 1.7 0 0 0-1.55-1H3a2 2 0 1 1 0-4h.09A1.7 1.7 0 0 0 4.64 8.9a1.7 1.7 0 0 0-.34-1.88l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.7 1.7 0 0 0 1.87.34H9a1.7 1.7 0 0 0 1-1.55V3a2 2 0 1 1 4 0v.09a1.7 1.7 0 0 0 1 1.55 1.7 1.7 0 0 0 1.88-.34l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.7 1.7 0 0 0-.34 1.87V9a1.7 1.7 0 0 0 1.55 1H21a2 2 0 1 1 0 4h-.09a1.7 1.7 0 0 0-1.51 1Z" />
  </svg>
)

export const IconPlus = ({ size = 18, className }: IconProps) => (
  <svg {...base(size)} className={className} strokeWidth={3}>
    <path d="M12 5v14M5 12h14" />
  </svg>
)

export const IconClose = ({ size = 20, className }: IconProps) => (
  <svg {...base(size)} className={className} strokeWidth={2.6}>
    <path d="M6 6l12 12M18 6 6 18" />
  </svg>
)

export const IconLock = ({ size = 18, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <rect x="4.5" y="10" width="15" height="10.5" rx="3" />
    <path d="M8 10V7.5a4 4 0 0 1 8 0V10" />
  </svg>
)

export const IconCheck = ({ size = 18, className }: IconProps) => (
  <svg {...base(size)} className={className} strokeWidth={3}>
    <path d="m4.5 12.5 5 5 10-11" />
  </svg>
)

export const IconPlay = ({ size = 26, className }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
    <path d="M8 4.8c0-1.2 1.3-1.9 2.3-1.3l9.4 6.1c1 .6 1 2 0 2.6l-9.4 6.1c-1 .6-2.3-.1-2.3-1.3V4.8Z" />
  </svg>
)

export const IconClock = ({ size = 18, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <circle cx="12" cy="12" r="8.6" />
    <path d="M12 7.4V12l3 2" />
  </svg>
)

export const IconGift = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <rect x="3.5" y="9" width="17" height="11.5" rx="2.4" />
    <path d="M3.5 13.5h17M12 9v11.5" />
    <path d="M12 9C10.6 5.4 8.7 4 7.3 5.3 6 6.7 7.6 9 12 9Zm0 0c1.4-3.6 3.3-5 4.7-3.7C18 6.7 16.4 9 12 9Z" />
  </svg>
)

export const IconGiftBox = ({ size = 26, className }: IconProps) => (
  <svg {...base(size)} className={className} strokeWidth={1.9}>
    <path d="M4 9.5h16V19a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 19V9.5Z" />
    <path d="M2.6 6.4h18.8v3.1H2.6zM12 6.4v15.1" />
    <path d="M12 6.4C10.2 1.9 6 1.2 5.4 3.5c-.6 2.3 2.5 3 6.6 2.9Zm0 0c1.8-4.5 6-5.2 6.6-2.9.6 2.3-2.5 3-6.6 2.9Z" />
  </svg>
)

export const IconSound = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M4 9.5h3.5L13 5.4v13.2L7.5 14.5H4z" />
    <path d="M16.5 8.5a5 5 0 0 1 0 7M19 6a8.5 8.5 0 0 1 0 12" />
  </svg>
)

export const IconMute = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M4 9.5h3.5L13 5.4v13.2L7.5 14.5H4z" />
    <path d="m17 9.5 5 5M22 9.5l-5 5" />
  </svg>
)

export const IconMap = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M9 4 3.5 6v14L9 18l6 2 5.5-2V4L15 6 9 4Z" />
    <path d="M9 4v14M15 6v14" />
  </svg>
)

export const IconHome = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="m3.5 10.5 8.5-7 8.5 7V20a1.5 1.5 0 0 1-1.5 1.5H5A1.5 1.5 0 0 1 3.5 20v-9.5Z" />
    <path d="M9.5 21.5v-6.8h5v6.8" />
  </svg>
)

export const IconPaw = ({ size = 22, className }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
    <ellipse cx="6.4" cy="9.6" rx="2.5" ry="3.1" transform="rotate(-18 6.4 9.6)" />
    <ellipse cx="17.6" cy="9.6" rx="2.5" ry="3.1" transform="rotate(18 17.6 9.6)" />
    <ellipse cx="10" cy="5.6" rx="2.2" ry="2.9" transform="rotate(-8 10 5.6)" />
    <ellipse cx="14" cy="5.6" rx="2.2" ry="2.9" transform="rotate(8 14 5.6)" />
    <path d="M12 11c3 0 5.6 2.6 5.6 5.1 0 1.9-1.5 3.1-3.3 3.1-1 0-1.6-.3-2.3-.3s-1.3.3-2.3.3c-1.8 0-3.3-1.2-3.3-3.1C6.4 13.6 9 11 12 11Z" />
  </svg>
)

export const IconTrophy = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M7 4h10v5a5 5 0 0 1-10 0V4Z" />
    <path d="M7 5.5H4.5V8A3.5 3.5 0 0 0 8 11.5M17 5.5h2.5V8a3.5 3.5 0 0 1-3.5 3.5M12 14v4M8 21h8M9 18h6" />
  </svg>
)

export const IconCalendar = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <rect x="3.5" y="5.5" width="17" height="15" rx="2.5" />
    <path d="M3.5 10h17M8 3.5V7M16 3.5V7" />
    <path d="M8 14h2M14 14h2M8 17.5h2M14 17.5h2" strokeWidth={2.6} />
  </svg>
)

export const IconEgg = ({ size = 24, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M12 2.8c3.7 0 6.7 5 6.7 9.6 0 3.9-2.7 6.8-6.7 6.8s-6.7-2.9-6.7-6.8C5.3 7.8 8.3 2.8 12 2.8Z" />
    <path d="m9.2 11 2.4 1.4-1.6 2.3 2.6 1.4" strokeWidth={1.7} />
  </svg>
)

export const IconSparkle = ({ size = 22, className }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
    <path d="M12 2.5c.5 4.5 2.7 6.8 7.2 7.3-4.5.5-6.7 2.8-7.2 7.3-.5-4.5-2.7-6.8-7.2-7.3 4.5-.5 6.7-2.8 7.2-7.3Z" />
    <path d="M18.5 15.2c.3 2.2 1.3 3.3 3.5 3.6-2.2.3-3.2 1.4-3.5 3.6-.3-2.2-1.3-3.3-3.5-3.6 2.2-.3 3.2-1.4 3.5-3.6Z" />
  </svg>
)

export const IconHeart = ({ size = 22, className }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
    <path d="M12 21s-8.5-4.7-8.5-10.2A4.8 4.8 0 0 1 12 7.3a4.8 4.8 0 0 1 8.5 3.5C20.5 16.3 12 21 12 21Z" />
  </svg>
)

export const IconBook = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M4 4.5h6a3 3 0 0 1 3 3v12a2.5 2.5 0 0 0-2.5-2.5H4v-12Z" />
    <path d="M20 4.5h-4a3 3 0 0 0-3 3v12a2.5 2.5 0 0 1 2.5-2.5H20v-12Z" />
  </svg>
)

export const IconInfo = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <circle cx="12" cy="12" r="9" />
    <path d="M12 11v5.5M12 7.8v.4" strokeWidth={2.6} />
  </svg>
)

export const IconRefresh = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M20 11.5a8 8 0 1 0-2.6 6" />
    <path d="M20 4.5v7h-7" />
  </svg>
)

export const IconShopping = ({ size = 22, className }: IconProps) => (
  <svg {...base(size)} className={className}>
    <path d="M3.5 4.5h2.2l2.5 11.2h9.7l2.1-8.2H6.6" />
    <circle cx="9" cy="19.5" r="1.6" />
    <circle cx="17.5" cy="19.5" r="1.6" />
  </svg>
)

export const IconBolt = ({ size = 22, className }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
    <path d="M13.4 2 4.8 13.2h6L10 22l9-11.6h-6.2L13.4 2Z" />
  </svg>
)

export const IconStar = ({ size = 20, className }: IconProps) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
    <path d="M12 2.6l2.8 5.9 6.4.9-4.7 4.5 1.2 6.4-5.7-3.1-5.7 3.1 1.2-6.4L2.8 9.4l6.4-.9L12 2.6Z" />
  </svg>
)
