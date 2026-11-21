import { useMemo, useState } from 'react'
import { useGame } from '../game/store'
import { HERO_STAGES, PETS, PET_BY_ID, RARITY } from '../game/data'
import { Btn, Gem, HintIcon, Modal, Progress, ScreenHeader, StarImg } from '../components/ui'
import { IconCheck, IconForward, IconLock, IconPaw, IconStar, IconBack } from '../components/Icon'
import { playSound } from '../game/audio'
import type { Pet, Rarity } from '../game/types'

const RARITY_TABS: Array<{ id: 'all' | Rarity; label: string; color: string }> = [
  { id: 'all', label: 'Все', color: '#c9a8ff' },
  { id: 'common', label: 'Обычные', color: RARITY.common.color },
  { id: 'uncommon', label: 'Необычные', color: RARITY.uncommon.color },
  { id: 'rare', label: 'Редкие', color: RARITY.rare.color },
  { id: 'epic', label: 'Эпики', color: RARITY.epic.color },
  { id: 'legendary', label: 'Легенды', color: RARITY.legendary.color },
]

const MYSTERY_SLOTS = 8
const PAGE_SIZE = 12

type Slot = { kind: 'pet'; pet: Pet } | { kind: 'locked'; id: string }

export default function Collection({ onBack, onSummon }: { onBack: () => void; onSummon: () => void }) {
  const { state, ownedCount, setFavorite, evolveHero, totalStars, toast } = useGame()
  const [tab, setTab] = useState<'all' | Rarity>('all')
  const [page, setPage] = useState(0)
  const [detail, setDetail] = useState<Pet | null>(null)

  const ownedPets = PETS.filter((p) => state.owned[p.id])
  const slots: Slot[] = useMemo(() => {
    const filtered = tab === 'all' ? PETS : PETS.filter((p) => p.rarity === tab)
    const list: Slot[] = filtered.map((pet) => ({ kind: 'pet', pet }))
    if (tab === 'all') {
      for (let i = 0; i < MYSTERY_SLOTS; i += 1) list.push({ kind: 'locked', id: `mystery-${i}` })
    }
    return list
  }, [tab])

  const pageCount = Math.max(1, Math.ceil(slots.length / PAGE_SIZE))
  const safePage = Math.min(page, pageCount - 1)
  const pageSlots = slots.slice(safePage * PAGE_SIZE, safePage * PAGE_SIZE + PAGE_SIZE)
  const totalSlots = PETS.length + MYSTERY_SLOTS

  const changeTab = (id: 'all' | Rarity) => {
    setTab(id)
    setPage(0)
    playSound('tap', 0.6)
  }

  const openPet = (pet: Pet) => {
    playSound('tap', 0.7)
    setDetail(pet)
  }

  const rarityInfo = detail ? RARITY[detail.rarity] : null
  const petCount = detail ? state.owned[detail.id] ?? 0 : 0

  return (
    <div className="screen collection">
      <div className="bg-layer bg-layer--collection" />
      <div className="collection-shade" />

      <ScreenHeader
        title="Коллекция"
        onBack={onBack}
        right={
          <>
            <span className="collection-counter">
              <IconPaw size={16} /> {ownedCount}/{totalSlots}
            </span>
            <button className="collection-summon" onClick={onSummon} aria-label="Открыть призыв">
              <IconStar size={17} />
            </button>
          </>
        }
      />

      <div className="collection-body">
        <aside className="collection-tabs" aria-label="Редкость">
          {RARITY_TABS.map((item) => {
            const count =
              item.id === 'all'
                ? ownedPets.length
                : ownedPets.filter((p) => p.rarity === item.id).length
            const total = item.id === 'all' ? totalSlots : PETS.filter((p) => p.rarity === item.id).length
            return (
              <button
                key={item.id}
                className={`collection-tab ${tab === item.id ? 'is-active' : ''}`}
                onClick={() => changeTab(item.id)}
              >
                <span className="collection-tab__dot" style={{ background: item.color }} />
                <span className="collection-tab__label">{item.label}</span>
                <span className="collection-tab__count">
                  {count}/{total}
                </span>
              </button>
            )
          })}
        </aside>

        <main className="collection-main">
          <div className="collection-progress">
            <span className="collection-progress__label">
              Собрано <b>{ownedCount}</b> из {totalSlots} питомцев
            </span>
            <Progress value={ownedCount} max={totalSlots} tone="purple" height={8} />
          </div>

          <div className="collection-grid">
            {pageSlots.map((slot) => {
              if (slot.kind === 'locked') {
                return (
                  <div key={slot.id} className="coll-card coll-card--locked">
                    <span className="coll-card__lock">
                      <IconLock size={16} />
                    </span>
                    <span className="coll-card__question">?</span>
                    <span className="coll-card__name">Скоро</span>
                  </div>
                )
              }
              const pet = slot.pet
              const owned = !!state.owned[pet.id]
              const rarity = RARITY[pet.rarity]
              const count = state.owned[pet.id] ?? 0
              if (!owned) {
                return (
                  <button key={pet.id} className="coll-card coll-card--locked" onClick={() => openPet(pet)}>
                    <span className="coll-card__lock">
                      <IconLock size={15} />
                    </span>
                    <span className="coll-card__question">?</span>
                    <span className="coll-card__name">Не открыт</span>
                  </button>
                )
              }
              return (
                <button
                  key={pet.id}
                  className="coll-card"
                  style={{ ['--rarity' as string]: rarity.color, ['--rarity-dark' as string]: rarity.dark }}
                  onClick={() => openPet(pet)}
                >
                  <span className="coll-card__frame" />
                  <span className="coll-card__glow" />
                  {count > 1 && <span className="coll-card__count">×{count}</span>}
                  {state.favorite === pet.id && (
                    <span className="coll-card__fav">
                      <IconCheck size={9} />
                    </span>
                  )}
                  <span className="coll-card__rarity" style={{ background: rarity.color }} />
                  {pet.id === 'murzik' && state.heroStage > 0 && (
                    <span className="coll-card__stage">Форма {state.heroStage + 1}</span>
                  )}
                  <img
                    src={pet.id === 'murzik' ? HERO_STAGES[state.heroStage].img : pet.img}
                    alt={pet.name}
                    className="coll-card__img"
                    draggable={false}
                  />
                  <span className="coll-card__name">{pet.name}</span>
                </button>
              )
            })}
          </div>

          <div className="collection-pager">
            <button
              className="collection-pager__arrow"
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={safePage === 0}
              aria-label="Предыдущая страница"
            >
              <IconBack size={16} />
            </button>
            <div className="collection-dots">
              {Array.from({ length: pageCount }, (_, i) => (
                <button
                  key={i}
                  className={`collection-dot ${i === safePage ? 'is-active' : ''}`}
                  onClick={() => setPage(i)}
                  aria-label={`Страница ${i + 1}`}
                />
              ))}
            </div>
            <button
              className="collection-pager__arrow"
              onClick={() => setPage((p) => Math.min(pageCount - 1, p + 1))}
              disabled={safePage >= pageCount - 1}
              aria-label="Следующая страница"
            >
              <IconForward size={16} />
            </button>
          </div>
        </main>
      </div>

      <div className="collection-footer">
        <span className="collection-footer__hint">Нажмите на карточку, чтобы узнать историю питомца</span>
        <Btn
          variant="white"
          size="sm"
          onClick={() => {
            const fav = PET_BY_ID[state.favorite]
            if (fav) setDetail(fav)
          }}
        >
          Любимец
        </Btn>
      </div>

      <Modal open={!!detail} onClose={() => setDetail(null)} className="pet-modal">
        {detail && rarityInfo && (
          <div className="pet-detail" style={{ ['--rarity' as string]: rarityInfo.color, ['--rarity-dark' as string]: rarityInfo.dark }}>
            <div className="pet-detail__scroll">
              <div className="pet-detail__hero">
                <span className="pet-detail__rays" />
                <img src={detail.id === 'murzik' ? HERO_STAGES[state.heroStage].img : detail.img} alt={detail.name} draggable={false} />
                <span className="pet-detail__rarity rarity-chip" style={{ ['--rarity' as string]: rarityInfo.color }}>
                  {rarityInfo.label}
                </span>
              </div>
              <h3 className="pet-detail__name">{detail.name}</h3>
              <p className="pet-detail__title">{detail.title}</p>
              {petCount > 0 ? (
                <>
                  <div className="pet-detail__meta">
                    <span>В коллекции: ×{petCount}</span>
                    {state.favorite === detail.id && <span className="pet-detail__fav-tag">Любимец</span>}
                  </div>
                  <p className="pet-detail__desc">{detail.desc}</p>
                  <div className="pet-stats">
                    {[
                      ['Внимание', detail.stats[0], '#ffd257'],
                      ['Скорость', detail.stats[1], '#7fd8ff'],
                      ['Удача', detail.stats[2], '#9df0b8'],
                    ].map(([label, value, color]) => (
                      <div key={label as string} className="pet-stat">
                        <span className="pet-stat__label">{label}</span>
                        <span className="pet-stat__bar">
                          <span style={{ width: `${value as number}%`, background: color as string }} />
                        </span>
                        <b>{value as number}</b>
                      </div>
                    ))}
                  </div>

                  {detail.id === 'murzik' && (
                    <div className="evolution">
                      <div className="evolution__head">
                        <span>Эволюция Мурзика</span>
                        <span className="evolution__stars"><StarImg size={14} /> {totalStars}</span>
                      </div>
                      <div className="evolution__stages">
                        {HERO_STAGES.map((stage, index) => (
                          <div
                            key={stage.name}
                            className={`evolution__stage ${index === state.heroStage ? 'is-current' : ''} ${index < state.heroStage ? 'is-done' : ''}`}
                          >
                            <img src={stage.img} alt={stage.name} draggable={false} />
                            <span>{stage.label}</span>
                            {index < state.heroStage && <em>✓</em>}
                          </div>
                        ))}
                      </div>
                      {state.heroStage < 2 ? (
                        <>
                          <div className="evolution__req">
                            <span><StarImg size={14} /> {HERO_STAGES[state.heroStage + 1].stars}</span>
                            <span><Gem size={15} /> {HERO_STAGES[state.heroStage + 1].gems}</span>
                          </div>
                          <Btn
                            variant="gold"
                            size="md"
                            full
                            onClick={() => {
                              if (evolveHero()) setDetail(null)
                              else toast('Не хватает звёзд или кристаллов', 'bad', 'spark')
                            }}
                          >
                            Эволюционировать
                          </Btn>
                        </>
                      ) : (
                        <p className="evolution__max">Максимальная форма достигнута</p>
                      )}
                    </div>
                  )}
                </>
              ) : (
                <>
                  <p className="pet-detail__desc">{detail.desc}</p>
                  <div className="hint">
                    <HintIcon />
                    <span>Этот питомец ещё не открыт. Попробуйте призыв — яйца внимания полны сюрпризов!</span>
                  </div>
                </>
              )}
            </div>

            <div className="pet-detail__actions">
              {petCount > 0 ? (
                <Btn
                  variant={state.favorite === detail.id ? 'ghost' : 'purple'}
                  size="md"
                  full
                  onClick={() => {
                    if (state.favorite === detail.id) return
                    setFavorite(detail.id)
                    toast(`${detail.name} теперь гуляет с вами на главной!`, 'good', 'paw')
                    setDetail(null)
                  }}
                  disabled={state.favorite === detail.id}
                >
                  {state.favorite === detail.id ? 'Уже любимец' : 'Сделать любимцем'}
                </Btn>
              ) : (
                <Btn variant="gold" size="md" full onClick={onSummon}>
                  Открыть призыв
                </Btn>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
