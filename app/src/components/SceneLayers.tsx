type Scene = 'home' | 'summon'

/** Декорация не участвует в управлении и скрыта от скринридера. */
export default function SceneLayers({ scene }: { scene: Scene }) {
  return (
    <div className={`scene-layers scene-layers--${scene}`} aria-hidden="true">
      <div className={`bg-layer bg-layer--${scene}`} />
      {scene === 'home' && (
        <div className="scene-layers__island">
          <img src="/assets/layers/floating_island.png" alt="" draggable={false} />
        </div>
      )}
    </div>
  )
}
