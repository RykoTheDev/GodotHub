import type { ThemePreset } from '../../lib/colors'

export function ThemePresetPreview({ preset }: { preset: ThemePreset }) {
  return (
    <div
      className="w-full rounded-md overflow-hidden border"
      style={{ backgroundColor: preset.base, borderColor: preset.line }}
    >
      <div
        className="flex items-center gap-1 px-2 py-1.5"
        style={{
          backgroundColor: preset.surface,
          borderBottom: `1px solid ${preset.line}`,
        }}
      >
        <span
          className="w-1.5 h-1.5 rounded-full"
          style={{ backgroundColor: preset.danger }}
        />
        <span
          className="w-1.5 h-1.5 rounded-full"
          style={{ backgroundColor: preset.amber }}
        />
        <span
          className="w-1.5 h-1.5 rounded-full"
          style={{ backgroundColor: preset.mint }}
        />
        <span
          className="ml-auto w-7 h-1 rounded-full"
          style={{ backgroundColor: preset.line }}
        />
      </div>

      <div className="flex gap-1.5 p-2">
        <div
          className="flex flex-col gap-1 p-1 rounded-[3px]"
          style={{ backgroundColor: preset.surface }}
        >
          <span
            className="w-2 h-1 rounded-full"
            style={{ backgroundColor: preset.accent }}
          />
          <span
            className="w-2 h-1 rounded-full"
            style={{ backgroundColor: preset.line }}
          />
          <span
            className="w-2 h-1 rounded-full"
            style={{ backgroundColor: preset.line }}
          />
        </div>
        <div className="flex-1 flex flex-col gap-1">
          <div
            className="rounded-[3px] p-1.5"
            style={{
              backgroundColor: preset.raised,
              border: `1px solid ${preset.line}`,
            }}
          >
            <span
              className="block h-1 rounded-full w-3/4"
              style={{ backgroundColor: preset.ink }}
            />
            <span
              className="block h-1 rounded-full w-1/2 mt-1"
              style={{ backgroundColor: preset.muted }}
            />
          </div>
          <div className="flex items-center gap-1">
            <span
              className="flex-1 h-1 rounded-full"
              style={{ backgroundColor: preset.line }}
            />
            <span
              className="w-3 h-2 rounded-xs"
              style={{ backgroundColor: preset.accent }}
            />
          </div>
        </div>
      </div>

      <div
        className="flex items-center gap-1.5 px-2 py-1.5"
        style={{
          backgroundColor: preset.surface,
          borderTop: `1px solid ${preset.line}`,
        }}
      >
        <span
          className="w-2 h-2 rounded-full ring-1 ring-black/20"
          style={{ backgroundColor: preset.accent }}
        />
        <span
          className="w-2 h-2 rounded-full ring-1 ring-black/20"
          style={{ backgroundColor: preset.accentBright }}
        />
        <span
          className="w-2 h-2 rounded-full ring-1 ring-black/20"
          style={{ backgroundColor: preset.mint }}
        />
        <span
          className="w-2 h-2 rounded-full ring-1 ring-black/20"
          style={{ backgroundColor: preset.amber }}
        />
        <span
          className="w-2 h-2 rounded-full ring-1 ring-black/20"
          style={{ backgroundColor: preset.danger }}
        />
      </div>
    </div>
  )
}
