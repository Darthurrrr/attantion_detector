export type GameProps = {
  levelId: number
  onFinish: (score: number, pairs: number) => void
}

export function starsFor(score: number): number {
  if (score >= 80) return 3
  if (score >= 55) return 2
  return 1
}

export function clamp(value: number, min = 0, max = 100) {
  return Math.max(min, Math.min(max, value))
}

export function shuffle<T>(items: T[]): T[] {
  const copy = [...items]
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[copy[i], copy[j]] = [copy[j], copy[i]]
  }
  return copy
}
