import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { useGame } from '../game/store'
import { playSound } from '../game/audio'
import { IconClose, IconClock, IconGiftBox, IconInfo, IconLock, IconPaw, IconSparkle, IconTrophy, IconPlus } from './Icon'
import type { Pet } from '../game/types'
import { RARITY } from '../game/data'

export function Coin({ size = 22, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" className={`coin-icon ${className}`} aria-hidden>
      <defs>
        <radialGradient id="coinFace" cx="35%" cy="28%" r="78%">
          <stop offset="0%" stopColor="#fff3b0" />
          <stop offset="45%" stopColor="#ffc93c" />
          <stop offset="100%" stopColor="#e08a12" />
        </radialGradient>
      </defs>
      <circle cx="16" cy="17.4" r="13" fill="#a35a0a" />
      <circle cx="16" cy="15.6" r="13" fill="url(#coinFace)" stroke="#8a4a06" strokeWidth="1.6" />
      <circle cx="16" cy="15.6" r="9.4" fill="none" stroke="#fff0a8" strokeWidth="1.5" opacity=".75" />
      <path
        d="M16 9.4c.7 2.5 1.7 3.5 4.2 4.2-2.5.7-3.5 1.7-4.2 4.2-.7-2.5-1.7-3.5-4.2-4.2 2.5-.7 3.5-1.7 4.2-4.2Z"
        fill="#fff6c9"
        stroke="#b96d08"
        strokeWidth=".7"
      />
      <ellipse cx="11.5" cy="9.6" rx="3.4" ry="2" fill="#fff" opacity=".55" transform="rotate(-28 11.5 9.6)" />
    </svg>
  )
}

export function Gem({ size = 22, className = '' }: { size?: number; className?: string }) {
  return <img src="/assets/ui/gem.png" width={size} height={size} alt="" className={`gem-icon ${className}`} draggable={false} />
}

export function StarImg({ size = 22, filled = true, className = '' }: { size?: number; filled?: boolean; className?: string }) {
  return (
    <img
      src="/assets/ui/star.png"
      width={size}
      height={size}
      alt=""
      draggable={false}
      className={`star-icon ${filled ? '' : 'is-empty'} ${className}`}
    />
  )
}

export function HeartIcon({ size = 22, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 30" className={`heart-icon ${className}`} aria-hidden>
      <defs>
        <linearGradient id="heartBody" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#ffd0e4" />
          <stop offset="42%" stopColor="#ff8fbe" />
          <stop offset="100%" stopColor="#e8508f" />
        </linearGradient>
      </defs>
      <path
        d="M16 27.4c-.6 0-1.1-.2-1.6-.6C8.9 21.9 3 16.7 3 10.6 3 6.1 6.4 2.8 10.6 2.8c2.2 0 4.2 1 5.4 2.6 1.2-1.6 3.2-2.6 5.4-2.6C25.6 2.8 29 6.1 29 10.6c0 6.1-5.9 11.3-11.4 16.2-.5.4-1 .6-1.6.6Z"
        fill="url(#heartBody)"
        stroke="#c93a76"
        strokeWidth="1.4"
        strokeLinejoin="round"
      />
      <ellipse cx="10.4" cy="9.6" rx="3.1" ry="2" fill="#fff" opacity=".55" transform="rotate(-28 10.4 9.6)" />
    </svg>
  )
}

export function StarsRow({ stars, size = 26, max = 3 }: { stars: number; size?: number; max?: number }) {
  return (
    <span className="stars-row" style={{ ['--star-size' as string]: `${size}px` }}>
      {Array.from({ length: max }, (_, i) => (
        <StarImg key={i} size={size} filled={i < stars} />
      ))}
    </span>
  )
}

export function ResPill({
  type,
  amount,
  onAdd,
  compact,
}: {
  type: 'coin' | 'gem'
  amount: number
  onAdd?: () => void
  compact?: boolean
}) {
  return (
    <div className={`res-pill ${compact ? 'is-compact' : ''}`}>
      {type === 'coin' ? <Coin size={compact ? 20 : 23} /> : <Gem size={compact ? 20 : 23} />}
      <span className="res-pill__value">{formatNumber(amount)}</span>
      {onAdd && (
        <button className="res-pill__add" onClick={onAdd} aria-label={type === 'coin' ? 'Пополнить монеты' : 'Пополнить кристаллы'}>
          <IconPlus size={13} />
        </button>
      )}
    </div>
  )
}

export function formatNumber(value: number) {
  return value.toLocaleString('ru-RU')
}

export function Btn({
  children,
  onClick,
  variant = 'gold',
  size = 'md',
  full,
  disabled,
  icon,
  className = '',
  ariaLabel,
}: {
  children: ReactNode
  onClick?: () => void
  variant?: 'gold' | 'purple' | 'green' | 'ghost' | 'white' | 'rose'
  size?: 'sm' | 'md' | 'lg'
  full?: boolean
  disabled?: boolean
  icon?: ReactNode
  className?: string
  ariaLabel?: string
}) {
  return (
    <button
      className={`btn btn--${variant} btn--${size} ${full ? 'btn--full' : ''} ${className}`}
      onClick={() => {
        if (disabled) return
        playSound('tap', 0.7)
        onClick?.()
      }}
      disabled={disabled}
      aria-label={ariaLabel}
    >
      {icon && <span className="btn__icon">{icon}</span>}
      <span className="btn__label">{children}</span>
    </button>
  )
}

export function IconButton({
  children,
  onClick,
  label,
  className = '',
  tone = 'purple',
}: {
  children: ReactNode
  onClick?: () => void
  label: string
  className?: string
  tone?: 'purple' | 'light' | 'gold'
}) {
  return (
    <button
      className={`icon-btn icon-btn--${tone} ${className}`}
      onClick={() => {
        playSound('tap', 0.55)
        onClick?.()
      }}
      aria-label={label}
      title={label}
    >
      {children}
    </button>
  )
}

export function Ribbon({ children, tone = 'purple', className = '' }: { children: ReactNode; tone?: 'purple' | 'gold'; className?: string }) {
  return (
    <div className={`ribbon ribbon--${tone} ${className}`}>
      <span className="ribbon__text">{children}</span>
    </div>
  )
}

export function Progress({
  value,
  max,
  tone = 'gold',
  height = 12,
  className = '',
  showLabel,
}: {
  value: number
  max: number
  tone?: 'gold' | 'blue' | 'green' | 'purple'
  height?: number
  className?: string
  showLabel?: string
}) {
  const pct = Math.max(0, Math.min(100, (value / Math.max(1, max)) * 100))
  return (
    <div className={`progress progress--${tone} ${className}`} style={{ height }}>
      <div className="progress__fill" style={{ width: `${pct}%` }} />
      {showLabel && <span className="progress__label">{showLabel}</span>}
    </div>
  )
}

export function Modal({
  open,
  onClose,
  children,
  className = '',
  closeLabel = 'Закрыть',
}: {
  open: boolean
  onClose: () => void
  children: ReactNode
  className?: string
  closeLabel?: string
}) {
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  if (!open) return null
  return (
    <div className="modal-layer" role="dialog" aria-modal="true">
      <button className="modal-layer__backdrop" onClick={onClose} aria-label={closeLabel} />
      <div className={`modal-card ${className}`}>
        <button className="modal-card__close" onClick={onClose} aria-label={closeLabel}>
          <IconClose size={18} />
        </button>
        {children}
      </div>
    </div>
  )
}

const TOAST_ICONS: Record<string, ReactNode> = {
  gem: <Gem size={18} />,
  coin: <Coin size={18} />,
  gift: <IconGiftBox size={18} />,
  star: <StarImg size={18} />,
  paw: <IconPaw size={18} />,
  lock: <IconLock size={16} />,
  trophy: <IconTrophy size={18} />,
  spark: <IconSparkle size={18} />,
  tasks: <IconClock size={18} />,
  clock: <IconClock size={18} />,
}

export function ToastLayer() {
  const { toasts, dismissToast } = useGame()
  return (
    <div className="toast-layer" aria-live="polite">
      {toasts.map((t) => (
        <button key={t.id} className={`toast toast--${t.tone}`} onClick={() => dismissToast(t.id)}>
          {t.icon && <span className="toast__icon">{TOAST_ICONS[t.icon] ?? null}</span>}
          <span>{t.text}</span>
        </button>
      ))}
    </div>
  )
}

export function HintIcon({ size = 17 }: { size?: number }) {
  return (
    <span className="hint__icon">
      <IconInfo size={size} />
    </span>
  )
}

export function Confetti({ active, pieces = 34 }: { active: boolean; pieces?: number }) {
  const items = useMemo(
    () =>
      Array.from({ length: pieces }, (_, i) => ({
        id: i,
        left: Math.random() * 100,
        delay: Math.random() * 0.5,
        duration: 1.7 + Math.random() * 1.4,
        size: 6 + Math.random() * 9,
        rotate: Math.random() * 360,
        color: ['#ffd257', '#ff7fb1', '#8ad8ff', '#b58bff', '#8ff1a8', '#fff'][i % 6],
        round: Math.random() > 0.55,
      })),
    [pieces, active],
  )
  if (!active) return null
  return (
    <div className="confetti" aria-hidden>
      {items.map((p) => (
        <span
          key={p.id}
          className={p.round ? 'confetti__piece confetti__piece--round' : 'confetti__piece'}
          style={{
            left: `${p.left}%`,
            width: p.size,
            height: p.size * (p.round ? 1 : 1.6),
            background: p.color,
            animationDelay: `${p.delay}s`,
            animationDuration: `${p.duration}s`,
            transform: `rotate(${p.rotate}deg)`,
          }}
        />
      ))}
    </div>
  )
}

export function Countdown({ to, prefix = '' }: { to: number; prefix?: string }) {
  const [now, setNow] = useState(Date.now())
  useEffect(() => {
    const id = window.setInterval(() => setNow(Date.now()), 1000)
    return () => window.clearInterval(id)
  }, [])
  const left = Math.max(0, to - now)
  const h = Math.floor(left / 3600000)
  const m = Math.floor((left % 3600000) / 60000)
  const s = Math.floor((left % 60000) / 1000)
  const pad = (n: number) => String(n).padStart(2, '0')
  return (
    <span className="countdown">
      {prefix}
      {pad(h)}:{pad(m)}:{pad(s)}
    </span>
  )
}

export function PetCardArt({ pet, className = '' }: { pet: Pet; className?: string }) {
  return (
    <div className={`pet-art ${className}`} style={{ ['--rarity' as string]: RARITY[pet.rarity].color }}>
      <span className="pet-art__glow" />
      <img src={pet.img} alt={pet.name} draggable={false} />
    </div>
  )
}

export function ScreenHeader({
  title,
  onBack,
  right,
  tone = 'purple',
}: {
  title: string
  onBack: () => void
  right?: ReactNode
  tone?: 'purple' | 'gold'
}) {
  return (
    <header className="screen-header">
      <IconButton label="Назад" onClick={onBack} className="screen-header__back">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round">
          <path d="M15 5 8 12l7 7" />
        </svg>
      </IconButton>
      <Ribbon tone={tone}>{title}</Ribbon>
      <div className="screen-header__right">{right}</div>
    </header>
  )
}
