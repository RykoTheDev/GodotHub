import {useCallback,useEffect,useRef,useState} from 'react'
import {AnimatePresence} from 'framer-motion'
import {useTranslation} from 'react-i18next'
import {api} from '../../lib/api'
import {pushToast} from '../../lib/toast'
import {useTauriEvent} from '../../lib/useTauriEvent'
import {useExportTemplateDownloads} from '../../hooks/useExportTemplateDownloads'
import type {Project,ProjectExportCatalog,ProjectExportRun} from '../../types'
import {IconChevronDown,IconDownload,IconFolder,IconRefresh,IconRocket,IconSpinner,IconTerminal} from '../../lib/icons'
import {Dropdown} from '../ui/Dropdown'
import {ModalShell} from './ModalShell'
import {ConfirmDialog} from './ConfirmDialog'
import {ExportTemplatesModal} from './ExportTemplatesModal'
import {formatBytes} from '../../lib/formatBytes'

const button = 'focus-ring cursor-pointer inline-flex items-center gap-2 rounded-btn border border-line bg-raised px-3 py-2 text-xs font-medium text-ink hover:border-accent-dim hover:bg-overlay transition-colors disabled:opacity-40 disabled:cursor-not-allowed'

export function ProjectBuildModal({project,onClose}: {project: Project;onClose:()=>void}) {
  const {t} = useTranslation('common', {keyPrefix:'build_export'})
  const {t:tc} = useTranslation('common')
  const [catalog,setCatalog] = useState<ProjectExportCatalog|null>(null)
  const [selected,setSelected] = useState<number|null>(null)
  const [output,setOutput] = useState('')
  const [error,setError] = useState('')
  const [loading,setLoading] = useState(true)
  const [starting,setStarting] = useState(false)
  const [templates,setTemplates] = useState(false)
  const [overwrite,setOverwrite] = useState(false)
  const [run,setRun] = useState<ProjectExportRun|null>(null)
  const mounted = useRef(true)
  const mutation = useRef(false)
  const sequence = useRef(0)
  const initialFocus = useRef<HTMLButtonElement>(null)
  const content = useRef<HTMLDivElement>(null)
  const selectedRef = useRef(selected)
  const presetsOpen = useRef(false)
  selectedRef.current = selected
  const refresh = useCallback(async()=>{
    if(!mounted.current)return
    const request = ++sequence.current
    setLoading(true);setError('')
    try {
      const [next, runs] = await Promise.all([api.getProjectExportPresets(project.id),api.getProjectExports(project.id)])
      if (!mounted.current || request !== sequence.current) return
      setCatalog(next)
      const active=runs.find(job=>job.status==='running')
      setRun(active??runs[0]??null)
      if(active){
        setSelected(next.presets.find(p=>p.name===active.preset_name)?.id??null)
        setOutput(active.output_path)
      } else if (!next.presets.some(p=>p.id===selectedRef.current)) {
        const first=next.presets[0]
        setOutput(first?.output_path??'')
        setSelected(first?.id??null)
      }
    } catch(reason) {if(mounted.current && request===sequence.current)setError(String(reason))}
    finally {if(mounted.current && request===sequence.current)setLoading(false)}
  },[project.id,project.godot_version])
  useEffect(()=>{mounted.current=true;void refresh();return()=>{mounted.current=false;sequence.current++}},[refresh])
  useEffect(()=>{
    const previous=document.activeElement as HTMLElement|null
    initialFocus.current?.focus()
    return()=>previous?.focus()
  },[])
  useEffect(()=>{
    const dialog=content.current?.closest<HTMLElement>('[role="dialog"]')
    const trigger=document.activeElement as HTMLElement|null
    if(dialog)dialog.inert=templates||overwrite
    const dialogs=[...document.querySelectorAll<HTMLElement>('[role="dialog"]')]
    const active=templates||overwrite?dialogs[dialogs.length-1]:dialog
    if(overwrite)active?.querySelector<HTMLElement>('button')?.focus()
    const keyboard=(event:KeyboardEvent)=>{
      if(presetsOpen.current)return
      if(event.target instanceof Element&&event.target.closest('[role="menu"]'))return
      if(event.key==='Escape'){
        if(templates)return
        event.preventDefault();event.stopPropagation()
        if(overwrite)setOverwrite(false)
        else onClose()
      }
      if(event.key!=='Tab'||templates)return
      const focusable=[...(active?.querySelectorAll<HTMLElement>('button:not(:disabled), input:not(:disabled), textarea:not(:disabled), [tabindex="0"]')??[])].filter(el=>!el.closest('[inert]'))
      const first=focusable[0],last=focusable[focusable.length-1]
      if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus()}
      else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first?.focus()}
    }
    document.addEventListener('keydown',keyboard,true)
    return()=>{
      if(dialog)dialog.inert=false
      document.removeEventListener('keydown',keyboard,true)
      if((templates||overwrite)&&trigger?.isConnected)requestAnimationFrame(()=>trigger.focus())
    }
  },[templates,overwrite,onClose])
  useTauriEvent<string>('export-templates-complete',tag=>{if(tag===catalog?.version_tag)void refresh()},[catalog?.version_tag,refresh])
  useTauriEvent<ProjectExportRun>('export:finished',finished=>{
    if(finished.id===run?.id)setRun(finished)
  },[run?.id])
  useEffect(()=>{
    if(!run || run.status!=='running')return
    let active=true
    const tick=()=>api.getProjectExport(run.id).then(next=>{if(active)setRun(next)}).catch(()=>{})
    void tick()
    const timer=setInterval(()=>void tick(),700)
    return()=>{active=false;clearInterval(timer)}
  },[run?.id,run?.status])
  const {downloads,install}=useExportTemplateDownloads(refresh)
  const preset=catalog?.presets.find(p=>p.id===selected)
  const running=run?.status==='running'
  const downloading=!!catalog && !!downloads[catalog.version_tag]
  const blocked=loading||starting||running||!!catalog?.engine_error||!preset||!!preset.template_error||!!preset.missing_templates.length||!output.trim()
  const openConsole=(job:ProjectExportRun)=>window.dispatchEvent(new CustomEvent('app:open-console',{detail:{id:job.id,name:`${job.project_name} · ${job.preset_name}`,exportRun:job}}))
  const start=async(replace=false)=>{
    if(!preset || blocked || mutation.current)return
    mutation.current=true;setStarting(true);setError('');setOverwrite(false)
    try {
      const job=await api.startProjectExport(project.id,preset.id,output,replace)
      if(mounted.current)setRun(job)
      openConsole(job)
      onClose()
    } catch(reason) {
      const message=String(reason)
      if(!mounted.current)return
      if(message.startsWith('OUTPUT_EXISTS:'))setOverwrite(true)
      else {setError(message);if(message.startsWith('INSTALL_EXPORT_TEMPLATES:'))void refresh()}
    } finally {mutation.current=false;if(mounted.current)setStarting(false)}
  }
  const browse=async()=>{
    try {const path=await api.pickSavePath(output.split(/[\\/]/).pop()||'game.zip');if(path&&mounted.current)setOutput(path)}
    catch(reason){pushToast('error',String(reason))}
  }
  return <>
    <ModalShell icon={<IconRocket className="w-5 h-5 text-accent-bright"/>} title={t('title')} description={t('description',{name:project.name})} onClose={onClose} maxWidth="max-w-2xl" bodyClassName="h-[min(60vh,34rem)] shrink" footer={<>
      {run&&<button className={button} onClick={()=>{openConsole(run);onClose()}}><IconTerminal className="w-3.5 h-3.5"/>{t('open_console')}</button>}
      <div className="ms-auto flex gap-2"><button ref={initialFocus} className={button} onClick={onClose}>{tc('close')}</button><button data-press-feedback className="focus-ring cursor-pointer inline-flex items-center justify-center gap-2 rounded-btn border border-accent-dim bg-accent px-4 py-2 text-xs font-medium text-white hover:bg-accent-bright transition-colors disabled:opacity-40 disabled:cursor-not-allowed" disabled={blocked} onClick={()=>void start()}>{starting?<IconSpinner className="w-3.5 h-3.5 animate-spin"/>:<IconRocket className="w-3.5 h-3.5"/>}{starting?t('starting'):t('start')}</button></div>
    </>}>
      <div ref={content} className="p-6 flex flex-col gap-5">
        <div className="flex items-center justify-between gap-3"><span className="text-xs text-muted">{catalog?.version_tag?t('engine',{version:catalog.version_tag}):t('release')}</span><button className={button} disabled={loading||starting||running} onClick={()=>void refresh()} aria-label={t('refresh')}><IconRefresh className={`w-3.5 h-3.5 ${loading?'animate-spin':''}`}/>{t('refresh')}</button></div>
        {loading&&!catalog?<p className="text-sm text-muted inline-flex items-center gap-2"><IconSpinner className="w-4 h-4 animate-spin"/>{t('loading')}</p>:<>
          {catalog?.engine_error&&<p role="alert" className="text-xs text-amber bg-amber/10 border border-amber/20 rounded-item p-3">{catalog.engine_error}</p>}
          {catalog?.presets.length===0?<div className="rounded-item border border-line bg-overlay p-5"><h3 className="text-sm font-medium">{t('no_presets')}</h3><p className="mt-2 text-xs text-muted leading-relaxed">{t('no_presets_hint')}</p><button className={`${button} mt-4`} disabled={!!catalog.engine_error} onClick={()=>void api.openProject(project.id,true).catch(reason=>pushToast('error',String(reason)))}>{t('open_editor')}</button></div>:preset&&<>
            <div className="flex flex-col gap-2"><label className="text-xs font-medium text-muted">{t('preset')}</label><Dropdown className="w-full" align="left" onOpenChange={open=>{presetsOpen.current=open}} trigger={({open,toggle})=><button type="button" className={`${button} w-full justify-between`} aria-expanded={open} aria-label={t('preset')} disabled={starting||running} onClick={toggle}><span className="truncate">{preset.name} <span className="text-muted">· {preset.platform}</span></span><IconChevronDown className="w-3.5 h-3.5 shrink-0"/></button>} items={catalog!.presets.map(p=>({key:String(p.id),label:p.name,badge:p.platform,active:p.id===selected,onClick:()=>{setSelected(p.id);setOutput(p.output_path);setError('')}}))}/></div>
            <div className="flex flex-col gap-2"><label className="text-xs font-medium text-muted" htmlFor="export-output-path">{t('output')}</label><div className="flex gap-2"><input id="export-output-path" value={output} disabled={starting||running} onChange={e=>setOutput(e.target.value)} className="focus-ring min-w-0 flex-1 rounded-item border border-line bg-overlay px-3 py-2.5 text-xs font-mono text-ink"/><button className={button} disabled={starting||running} onClick={()=>void browse()} aria-label={t('browse')}><IconFolder className="w-4 h-4"/></button></div><p className="text-[11px] leading-relaxed text-muted">{t('output_hint')}</p></div>
            {preset.template_error&&<p role="alert" className="text-xs text-danger">{preset.template_error}</p>}
            {preset.missing_templates.length>0&&<div className="rounded-item border border-amber/25 bg-amber/10 p-4"><p className="text-xs text-amber leading-relaxed">{t('missing_templates')}</p><p className="mt-2 text-[11px] font-mono text-muted break-all">{preset.missing_templates.join(', ')}</p><button className={`${button} mt-3`} disabled={downloading||starting||running} onClick={()=>setTemplates(true)}><IconDownload className="w-3.5 h-3.5"/>{downloading?t('downloading_templates'):t('install_templates')}</button></div>}
          </>}
        </>}
        {error&&<p role="alert" className="text-xs text-danger rounded-item border border-danger/20 bg-danger/10 p-3 whitespace-pre-wrap">{error}</p>}
        {run&&<div role="status" className="rounded-item border border-line bg-overlay p-4"><h3 className={`text-sm font-medium ${run.status==='failed'?'text-danger':run.status==='succeeded'?'text-mint':'text-ink'}`}>{run.status==='running'?t('running',{preset:run.preset_name}):t(run.status)}</h3><p className="mt-2 text-xs font-mono break-all text-muted">{run.output_path}{run.size_bytes!==null?` · ${formatBytes(run.size_bytes)}`:''}</p>{run.error&&<p className="mt-2 text-xs text-danger whitespace-pre-wrap">{run.error}</p>}{run.status==='cancelled'&&<p className="mt-2 text-xs text-muted">{t('cancel_hint')}</p>}<div className="mt-3 flex gap-2">{running&&<button className={button} onClick={()=>void api.cancelProjectExport(run.id).catch(reason=>pushToast('error',String(reason)))}>{t('cancel_export')}</button>}{run.status==='succeeded'&&<button className={button} onClick={()=>void api.openExportArtifactFolder(run.id).catch(reason=>pushToast('error',String(reason)))}><IconFolder className="w-3.5 h-3.5"/>{t('open_folder')}</button>}</div></div>}
        <p className="text-[11px] text-muted leading-relaxed">{t('run_hint')} {t('platform_tools')}</p>
      </div>
    </ModalShell>
    <AnimatePresence>{templates&&catalog&&<ExportTemplatesModal tag={catalog.version_tag} onClose={()=>setTemplates(false)} onChanged={refresh} onDownload={files=>{setTemplates(false);void install(catalog.version_tag,files)}}/>}</AnimatePresence>
    <AnimatePresence>{overwrite&&<ConfirmDialog title={t('overwrite_title')} description={t('overwrite_description',{path:output})} confirmLabel={t('overwrite')} onConfirm={()=>void start(true)} onCancel={()=>setOverwrite(false)}/>}</AnimatePresence>
  </>
}
