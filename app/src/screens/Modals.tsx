import { useMemo, useState } from 'react'
import { useGame } from '../game/store'
import { DAILY_REWARDS, DAILY_TASKS, HERO_STAGES, LEVELS, PET_BY_ID } from '../game/data'
import { Btn, Coin, Countdown, Gem, HeartIcon, HintIcon, Modal, Progress, ResPill, StarImg } from '../components/ui'
import {
  IconBolt,
  IconCalendar,
  IconCheck,
  IconClock,
  IconGiftBox,
  IconMute,
  IconPaw,
  IconRefresh,
  IconSound,
  IconTrophy,
} from '../components/Icon'
import SceneBanner from '../components/SceneBanner'
import { playSound } from '../game/audio'
import type { ChestResult } from '../game/store'

function nextMidnight() {
  const d = new Date()
  d.setHours(24, 0, 0, 0)
  return d.getTime()
}

export function TasksModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { state, taskProgress, claimTask } = useGame()
  const done = DAILY_TASKS.filter((t) => taskProgress(t.metric) >= t.goal).length

  return (
    <Modal open={open} onClose={onClose}>
      <h3 className="modal-title">Задания дня</h3>
      <p className="modal-sub">
        Выполнено {done} из {DAILY_TASKS.length} · обновление через <Countdown to={nextMidnight()} />
      </p>
      <div className="tasks-list">
        {DAILY_TASKS.map((task) => {
          const progress = Math.min(task.goal, taskProgress(task.metric))
          const complete = progress >= task.goal
          const claimed = state.tasks.claims.includes(task.id)
          return (
            <div key={task.id} className={`task-row ${claimed ? 'is-claimed' : ''}`}>
              <span className={`task-row__icon ${complete ? 'is-done' : ''}`}>
                {task.metric === 'summons' ? <IconGiftBox size={20} /> : task.metric === 'pairs' ? <IconPaw size={20} /> : task.metric === 'stars' ? <StarImg size={20} /> : <IconTrophy size={20} />}
              </span>
              <div className="task-row__body">
                <span className="task-row__title">{task.title}</span>
                <span className="task-row__progress">
                  <Progress value={progress} max={task.goal} tone={complete ? 'green' : 'gold'} height={7} />
                  <b>
                    {progress}/{task.goal}
                  </b>
                </span>
                <span className="task-row__rewards">
                  {task.coins > 0 && (
                    <em>
                      <Coin size={13} /> {task.coins}
                    </em>
                  )}
                  {task.gems > 0 && (
                    <em>
                      <Gem size={13} /> {task.gems}
                    </em>
                  )}
                </span>
              </div>
              {claimed ? (
                <span className="task-row__done">
                  <IconCheck size={15} /> Готово
                </span>
              ) : (
                <Btn variant={complete ? 'gold' : 'ghost'} size="sm" disabled={!complete} onClick={() => claimTask(task.id)}>
                  Забрать
                </Btn>
              )}
            </div>
          )
        })}
      </div>
      <div className="hint" style={{ marginTop: 12 }}>
        <HintIcon />
        <span>Задания обновляются каждый день в полночь. Заходите чаще, чтобы забирать больше наград!</span>
      </div>
    </Modal>
  )
}

export function DailyModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { state, canClaimDaily, claimDaily } = useGame()
  const [justClaimed, setJustClaimed] = useState(false)
  const streak = state.daily.streak
  const currentIndex = canClaimDaily ? streak % 7 : Math.max(0, (streak - 1) % 7)
  const claimedCount = canClaimDaily ? streak % 7 : Math.min(7, ((streak - 1) % 7) + 1)

  return (
    <Modal open={open} onClose={onClose}>
      <h3 className="modal-title">Ежедневная награда</h3>
      <p className="modal-sub">
        {streak > 0 ? (
          <>
            Серия: <b>{streak}</b> {streak === 1 ? 'день' : streak > 1 && streak < 5 ? 'дня' : 'дней'} подряд
          </>
        ) : (
          <>Серия ещё не начата — заберите первую награду</>
        )}
      </p>
      <div className="daily-grid">
        {DAILY_REWARDS.map((reward, index) => {
          const claimed = index < claimedCount
          const isToday = index === currentIndex && canClaimDaily
          return (
            <div key={index} className={`daily-cell ${claimed ? 'is-claimed' : ''} ${isToday ? 'is-today' : ''}`}>
              <span className="daily-cell__day">День {index + 1}</span>
              <span className="daily-cell__art">
                {index === 6 ? (
                  <IconGiftBox size={26} />
                ) : reward.gems > 0 ? (
                  <Gem size={24} />
                ) : (
                  <Coin size={24} />
                )}
              </span>
              <span className="daily-cell__label">{reward.label}</span>
              {claimed && (
                <span className="daily-cell__check">
                  <IconCheck size={11} />
                </span>
              )}
            </div>
          )
        })}
      </div>
      {canClaimDaily ? (
        <Btn
          variant="gold"
          size="lg"
          full
          icon={<IconGiftBox size={20} />}
          onClick={() => {
            const res = claimDaily()
            if (res) {
              setJustClaimed(true)
              playSound('reward')
            }
          }}
        >
          Забрать награду
        </Btn>
      ) : (
        <div className="daily-timer">
          <IconClock size={17} />
          <span>Следующая награда через</span>
          <Countdown to={state.daily.last + 24 * 60 * 60 * 1000} />
        </div>
      )}
      {justClaimed && !canClaimDaily && <p className="daily-got">Награда добавлена в кошелёк!</p>}
      <div className="hint" style={{ marginTop: 10 }}>
        <HintIcon />
        <span>Каждый день серии увеличивает награду. Пропустите день — серия начнётся заново.</span>
      </div>
    </Modal>
  )
}

export function EventsModal({ open, onClose, onDaily }: { open: boolean; onClose: () => void; onDaily: () => void }) {
  const { state, eventProgress, claimEvent, openChest } = useGame()
  const [chest, setChest] = useState<ChestResult | null>(null)
  const eventReady = eventProgress >= 5 && !state.event.claimed
  const daysLeft = 3

  return (
    <Modal open={open} onClose={onClose}>
      <h3 className="modal-title">События</h3>
      <p className="modal-sub">Особые награды и приключения этой недели</p>
      <SceneBanner scene="events" />

      <button className="event-card event-card--daily" onClick={onDaily}>
        <span className="event-card__art">
          <IconCalendar size={26} />
        </span>
        <span className="event-card__body">
          <b>Ежедневный подарок</b>
          <small>{state.daily.streak > 0 ? `Серия: ${state.daily.streak} дн.` : 'Заберите первую награду'}</small>
        </span>
        <span className="event-card__cta">Открыть</span>
      </button>

      <div className={`event-card event-card--marathon ${eventReady ? 'is-ready' : ''}`}>
        <span className="event-card__ribbon">
          <IconBolt size={13} /> Марафон внимания
        </span>
        <div className="event-card__head">
          <span className="event-card__art event-card__art--marathon">
            <IconTrophy size={26} />
          </span>
          <div className="event-card__body">
            <b>Сыграйте 5 мини-игр</b>
            <small>Осталось {daysLeft} дня · награда дня</small>
          </div>
        </div>
        <div className="event-card__progress">
          <Progress value={eventProgress} max={5} tone="purple" height={9} />
          <b>
            {eventProgress}/5
          </b>
        </div>
        <div className="event-card__rewards">
          <span>
            <Coin size={17} /> 350
          </span>
          <span>
            <Gem size={17} /> 14
          </span>
          <Btn variant={eventReady ? 'gold' : 'ghost'} size="sm" disabled={!eventReady} onClick={claimEvent}>
            {state.event.claimed ? 'Получено' : 'Забрать'}
          </Btn>
        </div>
      </div>

      <div className="event-card event-card--chest">
        <div className="event-card__head">
          <img src="/assets/ui/chest.png" alt="" className="event-card__chest" />
          <div className="event-card__body">
            <b>Сокровищница Мурзика</b>
            <small>Случайная награда, иногда — питомец</small>
          </div>
        </div>
        {chest && (
          <div className="chest-result">
            <span>В сундуке: <b>{chest.label}</b></span>
          </div>
        )}
        <Btn
          variant="purple"
          size="md"
          full
          icon={<Coin size={18} />}
          onClick={() => {
            const res = openChest()
            if (res) setChest(res)
          }}
          disabled={state.coins < 400}
        >
          Открыть за 400
        </Btn>
      </div>
    </Modal>
  )
}

export function ShopModal({
  open,
  onClose,
  tab,
}: {
  open: boolean
  onClose: () => void
  tab: 'coin' | 'gem'
}) {
  const { state, exchangeGems, openChest } = useGame()
  const [chest, setChest] = useState<ChestResult | null>(null)

  return (
    <Modal open={open} onClose={onClose}>
      <h3 className="modal-title">Магазин</h3>
      <div className="shop-balance">
        <ResPill type="coin" amount={state.coins} compact />
        <ResPill type="gem" amount={state.gems} compact />
      </div>
      <p className="modal-sub">
        {tab === 'gem' ? 'Кристаллы нужны для призыва и эволюции Мурзика.' : 'Монеты можно обменять на кристаллы или сундук.'}
      </p>
      <SceneBanner scene="shop" />

      <div className="shop-offer">
        <span className="shop-offer__icon shop-offer__icon--gem">
          <Gem size={34} />
        </span>
        <div className="shop-offer__body">
          <b>25 кристаллов</b>
          <small>Обменяйте монеты на кристаллы внимания</small>
          <span className="shop-offer__price">
            <Coin size={16} /> 250
          </span>
        </div>
        <Btn variant="gold" size="sm" onClick={exchangeGems} disabled={state.coins < 250}>
          Обменять
        </Btn>
      </div>

      <div className="shop-offer">
        <span className="shop-offer__icon">
          <img src="/assets/ui/chest.png" alt="" />
        </span>
        <div className="shop-offer__body">
          <b>Сундук внимания</b>
          <small>90–260 монет, кристаллы или питомец</small>
          <span className="shop-offer__price">
            <Coin size={16} /> 400
          </span>
        </div>
        <Btn
          variant="purple"
          size="sm"
          onClick={() => {
            const res = openChest()
            if (res) setChest(res)
          }}
          disabled={state.coins < 400}
        >
          Открыть
        </Btn>
      </div>

      {chest && (
        <div className="chest-result" style={{ marginTop: 10 }}>
          <span>В сундуке: <b>{chest.label}</b></span>
        </div>
      )}

      <div className="hint" style={{ marginTop: 12 }}>
        <HintIcon />
        <span>Монеты дают за уровни, задания и события. Кристаллы — за звёзды и особые награды.</span>
      </div>
    </Modal>
  )
}

export function SettingsModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { state, setVolume, toggleSound, rename, reset, totalStars, ownedCount } = useGame()
  const [name, setName] = useState(state.name)
  const [confirmReset, setConfirmReset] = useState(false)

  const stats = useMemo(
    () => [
      { label: 'Игр сыграно', value: state.totals.games },
      { label: 'Звёзд', value: totalStars },
      { label: 'Питомцев', value: ownedCount },
      { label: 'Рекорд', value: state.totals.best },
    ],
    [state.totals, totalStars, ownedCount],
  )

  return (
    <Modal open={open} onClose={onClose}>
      <h3 className="modal-title">Профиль и настройки</h3>
      <div className="settings-profile">
        <span className="settings-profile__avatar">
          <img src={state.favorite === 'murzik' ? '/assets/hero_avatar.png' : PET_BY_ID[state.favorite]?.img} alt="" />
          <b>{state.playerLevel}</b>
        </span>
        <div className="settings-profile__info">
          <label className="settings-label" htmlFor="player-name">
            Имя игрока
          </label>
          <input
            id="player-name"
            className="settings-input"
            value={name}
            maxLength={16}
            onChange={(e) => setName(e.target.value)}
            onBlur={() => rename(name)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                rename(name)
                ;(e.target as HTMLInputElement).blur()
              }
            }}
          />
        </div>
      </div>

      <div className="settings-stats">
        {stats.map((s) => (
          <div key={s.label} className="settings-stat">
            <b>{s.value}</b>
            <span>{s.label}</span>
          </div>
        ))}
      </div>

      <div className="settings-row">
        <span className="settings-row__icon">{state.settings.sound ? <IconSound size={20} /> : <IconMute size={20} />}</span>
        <span className="settings-row__label">Звуки</span>
        <button className={`toggle ${state.settings.sound ? 'is-on' : ''}`} onClick={toggleSound} aria-label="Переключить звук" />
      </div>
      <div className="settings-row settings-row--slider">
        <span className="settings-row__icon"><IconSound size={19} /></span>
        <span className="settings-row__label">Громкость</span>
        <input
          className="range"
          type="range"
          min="0"
          max="1"
          step="0.05"
          value={state.settings.volume}
          onChange={(e) => setVolume(Number(e.target.value))}
          aria-label="Громкость"
        />
      </div>

      <div className="settings-about">
        <span className="settings-about__logo">
          <img src={HERO_STAGES[0].img} alt="" />
        </span>
        <span>
          <b>Детектор внимания</b>
          <small>Приключения Мурзика · v1.0</small>
          <small>Глава 1 из {LEVELS.length} уровней · сделано с любовью к котикам</small>
        </span>
      </div>

      <div className="settings-actions">
        {confirmReset ? (
          <>
            <Btn variant="ghost" size="sm" onClick={() => setConfirmReset(false)}>
              Отмена
            </Btn>
            <Btn
              variant="rose"
              size="sm"
              icon={<IconRefresh size={16} />}
              onClick={() => {
                reset()
                setConfirmReset(false)
                onClose()
              }}
            >
              Точно сбросить
            </Btn>
          </>
        ) : (
          <Btn variant="ghost" size="sm" icon={<IconRefresh size={16} />} onClick={() => setConfirmReset(true)}>
            Сбросить прогресс
          </Btn>
        )}
      </div>
      <p className="settings-fineprint">
        <HeartIcon size={12} /> Прогресс сохраняется в этом браузере автоматически.
      </p>
    </Modal>
  )
}
