type Scene = 'events' | 'shop' | 'training'

const SCENES: Record<Scene, { background: string; art: string; eyebrow: string; caption: string }> = {
  events: {
    background: '/assets/bg/events_scene.webp',
    art: '/assets/ui/chest.png',
    eyebrow: 'ПРАЗДНИК НА ОСТРОВАХ',
    caption: 'Подарки ждут героев',
  },
  shop: {
    background: '/assets/bg/shop_scene.webp',
    art: '/assets/ui/egg_0.png',
    eyebrow: 'ВОЛШЕБНАЯ ЛАВКА',
    caption: 'Сокровища мира внимания',
  },
  training: {
    background: '/assets/bg/training_scene.webp',
    art: '/assets/pets/star.png',
    eyebrow: 'МИР ВНИМАНИЯ',
    caption: 'Вперёд к новым открытиям',
  },
}

/** Декоративная сценка, не влияющая на управление и результаты игры. */
export default function SceneBanner({ scene }: { scene: Scene }) {
  const item = SCENES[scene]
  return (
    <div className={`scene-banner scene-banner--${scene}`} aria-hidden="true">
      <div className="scene-banner__picture" style={{ backgroundImage: `url(${item.background})` }} />
      <div className="scene-banner__veil" />
      <span className="scene-banner__spark scene-banner__spark--one" />
      <span className="scene-banner__spark scene-banner__spark--two" />
      <span className="scene-banner__copy">
        <span>{item.eyebrow}</span>
        <b>{item.caption}</b>
      </span>
      <img className="scene-banner__art" src={item.art} alt="" draggable={false} />
    </div>
  )
}
