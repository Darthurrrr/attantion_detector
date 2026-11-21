type SoundName = 'tap' | 'success' | 'reward' | 'cuddle' | 'transition'

const FILES: Record<SoundName, string> = {
  tap: '/assets/sounds/ui_tap.wav',
  success: '/assets/sounds/success_chime.wav',
  reward: '/assets/sounds/crystal_reward.wav',
  cuddle: '/assets/sounds/pet_cuddle.wav',
  transition: '/assets/sounds/soft_transition.wav',
}

const cache = new Map<SoundName, HTMLAudioElement>()
let enabled = true
let volume = 0.7
let ctx: AudioContext | null = null

function getCtx(): AudioContext | null {
  if (typeof window === 'undefined') return null
  if (!ctx) {
    const Ctor = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
    if (!Ctor) return null
    ctx = new Ctor()
  }
  return ctx
}

export function setSoundEnabled(value: boolean) {
  enabled = value
}

export function setSoundVolume(value: number) {
  volume = Math.max(0, Math.min(1, value))
}

export function playSound(name: SoundName, gain = 1) {
  if (!enabled) return
  try {
    let audio = cache.get(name)
    if (!audio) {
      audio = new Audio(FILES[name])
      audio.preload = 'auto'
      cache.set(name, audio)
    }
    const node = audio.cloneNode(true) as HTMLAudioElement
    node.volume = Math.max(0, Math.min(1, volume * gain))
    void node.play().catch(() => undefined)
  } catch {
    /* звук не критичен */
  }
}

/** Короткий синтезированный тон для мелодии кристаллов. */
export function playTone(freq: number, duration = 0.22, type: OscillatorType = 'sine', gain = 0.18) {
  if (!enabled) return
  const audioCtx = getCtx()
  if (!audioCtx) return
  if (audioCtx.state === 'suspended') void audioCtx.resume()
  const osc = audioCtx.createOscillator()
  const vol = audioCtx.createGain()
  osc.type = type
  osc.frequency.value = freq
  const now = audioCtx.currentTime
  vol.gain.setValueAtTime(0, now)
  vol.gain.linearRampToValueAtTime(gain * volume, now + 0.015)
  vol.gain.exponentialRampToValueAtTime(0.0001, now + duration)
  osc.connect(vol)
  vol.connect(audioCtx.destination)
  osc.start(now)
  osc.stop(now + duration + 0.02)
}

export function haptic(pattern: number | number[] = 12) {
  if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
    try {
      navigator.vibrate(pattern)
    } catch {
      /* игнорируем */
    }
  }
}
