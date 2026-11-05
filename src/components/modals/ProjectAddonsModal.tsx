import {useCallback,useEffect,useRef,useState} from 'react'
import {useTranslation} from 'react-i18next'
import {api} from '../../lib/api'
import {pushToast} from '../../lib/toast'
import type {AddonUpdate,Project,ProjectAddon} from '../../types'
import {IconCloudArrowDown,IconPlug,IconRefresh,IconSpinner} from '../../lib/icons'
import {ModalShell} from './ModalShell'
import {ConfirmDialog} from './ConfirmDialog'

const button = 'focus-ring cursor-pointer inline-flex shrink-0 items-center gap-2 rounded-btn border border-line bg-raised px-3 py-2 text-xs font-medium text-ink hover:border-accent-dim hover:bg-overlay disabled:opacity-40 disabled:cursor-not-allowed'
const badge = 'inline-flex items-center h-5 px-2 rounded-tag border text-3xs font-medium'

export function ProjectAddonsModal({project,onClose}: {project: Project;onClose:()=>void}) {
  const {t} = useTranslation('common', {keyPrefix:'project_addons'})
  const {t:tc} = useTranslation('common')
  const [addons,setAddons] = useState<ProjectAddon[]|null>(null)
  const [updates,setUpdates] = useState<Record<string,AddonUpdate>|null>(null)
  const [checking,setChecking] = useState(false)
  const [updating,setUpdating] = useState<string|null>(null)
  const [confirm,setConfirm] = useState<AddonUpdate|null>(null)
  const [error,setError] = useState('')
  const mounted = useRef(true)

  const load = useCallback(async()=>{
    try {const result=await api.listProjectAddons(project.id);if(mounted.current)setAddons(result)}
    catch(reason){if(mounted.current){setAddons([]);setError(String(reason))}}
  },[project.id])

  const check = useCallback(async()=>{
    setChecking(true);setError('')
    try {
      const result=await api.checkAddonUpdates(project.id)
      if(mounted.current)setUpdates(Object.fromEntries(result.map(update=>[update.folder,update])))
    } catch(reason){if(mounted.current)setError(String(reason))}
    finally {if(mounted.current)setChecking(false)}
  },[project.id])

  useEffect(()=>{
    mounted.current=true
    void load()
    return()=>{mounted.current=false}
  },[load])

  const update=async(target:AddonUpdate)=>{
    setConfirm(null);setUpdating(target.folder);setError('')
    try {
      await api.updateProjectAddon(project.id,target.folder,target.asset_id)
      pushToast('success',t('updated',{name:target.title}))
      await load()
      await check()
    } catch(reason){if(mounted.current)setError(String(reason))}
    finally {if(mounted.current)setUpdating(null)}
  }

  const available=updates?Object.values(updates).filter(u=>u.update_available).length:0

  return <>
    <ModalShell icon={<IconPlug className="w-5 h-5 text-accent-bright"/>} title={t('title')} onClose={confirm?undefined:onClose} maxWidth="max-w-2xl" bodyClassName="h-[min(60vh,34rem)] shrink" footer={<>
      <p className="flex-1 text-2xs text-muted leading-relaxed">{t('footer_hint')}</p>
      <button className={button} onClick={onClose}>{tc('close')}</button>
    </>}>
      <div className="p-6 flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line pb-4">
          <div aria-live="polite">
            <p className="text-sm font-medium text-ink">{addons===null?t('loading'):t('count',{count:addons.length})}</p>
            {updates&&<p className="mt-1 text-xs text-muted">{available?t('updates_available',{count:available}):t('all_current')}</p>}
          </div>
          <button className={button} disabled={checking||!!updating||!addons?.length} onClick={()=>void check()}>
            <IconRefresh className={`w-3.5 h-3.5 ${checking?'animate-spin':''}`}/>{checking?t('checking'):t('check_updates')}
          </button>
        </div>
        {error&&<p role="alert" className="text-xs text-danger rounded-item border border-danger/20 bg-danger/10 p-3 whitespace-pre-wrap break-words">{error}</p>}
        {addons?.length===0&&<p className="text-xs text-muted leading-relaxed">{t('empty')}</p>}
        {addons?.map(addon=>{
          const info=updates?.[addon.folder]
          return <div key={addon.folder} className="flex items-start gap-3 rounded-item border border-line bg-overlay px-4 py-3">
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-sm font-medium text-ink truncate">{addon.name}</h3>
                {addon.version&&<span className="text-2xs font-mono text-muted">v{addon.version.replace(/^v/i,'')}</span>}
                {!addon.has_plugin?<span className={`${badge} border-line text-muted`}>{t('library')}</span>:addon.enabled?<span className={`${badge} border-mint/40 bg-mint/10 text-mint`}>{t('enabled')}</span>:<span className={`${badge} border-line text-muted`}>{t('disabled')}</span>}
                {addon.asset_id&&<span className={`${badge} border-accent-dim/40 bg-accent/10 text-accent-bright`}>{t('from_library')}</span>}
              </div>
              <p className="mt-1 text-2xs font-mono text-muted break-all">res://addons/{addon.folder}{addon.author?` · ${addon.author}`:''}</p>
              {addon.description&&<p className="mt-1.5 text-xs text-muted leading-relaxed line-clamp-2">{addon.description}</p>}
              {updates&&<p className={`mt-2 text-xs ${info?.update_available?'text-amber':'text-muted'}`}>
                {!info?t('not_found'):info.update_available?t('update_to',{version:info.latest_version||'?'}):t('current',{version:info.latest_version||'?'})}
                {info?.matched_by==='name'&&<span className="text-muted"> · {t('matched_by_name',{title:info.title})}</span>}
              </p>}
            </div>
            {info?.update_available&&<button className={button} disabled={!!updating||checking} onClick={()=>setConfirm(info)}>
              {updating===addon.folder?<IconSpinner className="w-3.5 h-3.5 animate-spin"/>:<IconCloudArrowDown className="w-3.5 h-3.5"/>}{updating===addon.folder?t('updating'):t('update')}
            </button>}
          </div>
        })}
      </div>
    </ModalShell>
    {confirm&&<ConfirmDialog title={t('confirm_title',{name:confirm.title})} description={t('confirm_description',{folder:confirm.folder,version:confirm.latest_version||'?'})} confirmLabel={t('update')} onConfirm={()=>void update(confirm)} onCancel={()=>setConfirm(null)}/>}
  </>
}
