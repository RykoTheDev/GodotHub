export function SplashScreen() {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-base">
      <div className="flex flex-col items-center gap-6 select-none">
        <div className="flex flex-col items-center gap-3">
          <h1 className="font-black italic tracking-tight leading-none text-ink text-[56px]">
            GodotHub
          </h1>

          <div className="relative h-[3px] w-40 rounded-full bg-raised overflow-hidden">
            <div className="absolute inset-y-0 w-1/2 rounded-full bg-linear-to-r from-transparent via-accent to-transparent" />
          </div>
        </div>
      </div>
    </div>
  )
}
