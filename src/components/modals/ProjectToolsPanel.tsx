import {useEffect,useState} from 'react'
import {useTranslation} from 'react-i18next'
import {api} from '../../lib/api'
import {pushToast} from '../../lib/toast'
import type {Project,ProjectTool} from '../../types'
import {IconCode,IconFlask,IconPlay,IconSpinner} from '../../lib/icons'

const button = 'focus-ring cursor-pointer inline-flex shrink-0 items-center gap-2 rounded-btn border border-line bg-raised px-3 py-2 text-xs font-medium text-ink hover:border-accent-dim hover:bg-overlay disabled:opacity-40 disabled:cursor-not-allowed'

export function ProjectToolsPanel({project,onStarted}: {project: Project;onStarted:()=>void}) {
  const {t} = useTranslation('common', {keyPrefix:'build_export'})
  const [tools,setTools] = useState<ProjectTool[]|null>(null)
  const [starting,setStarting] = useState<ProjectTool['id']|null>(null)

  useEffect(()=>{
    let active=true
    api.listProjectTools(project.id).then(result=>{if(active)setTools(result)}).catch(()=>{if(active)setTools([])})
    return()=>{active=false}
  },[project.id])

  const run=async(tool:ProjectTool)=>{
    setStarting(tool.id)
    try {
      const id=await api.runProjectTool(project.id,tool.id)
      window.dispatchEvent(new CustomEvent('app:open-console',{detail:{id,name:`${project.name} · ${t(`tool_${tool.id}`)}`}}))
      onStarted()
    } catch(reason) {pushToast('error',String(reason))}
    finally {setStarting(null)}
  }

  if(!tools)return null
  const hasTests=tools.some(tool=>tool.kind==='test')
  return <section className="flex flex-col gap-2 border-t border-line pt-5">
    <h3 className="text-xs font-medium text-muted">{t('tools_title')}</h3>
    {!hasTests&&<p className="text-2xs text-muted leading-relaxed">{t('tools_no_tests')}</p>}
    {tools.map(tool=>{
      const Icon=tool.kind==='test'?IconFlask:IconCode
      return <div key={tool.id} className="flex items-center gap-3 rounded-item border border-line bg-overlay px-3 py-2.5">
        <Icon className="w-3.5 h-3.5 shrink-0 text-muted"/>
        <div className="min-w-0 flex-1">
          <p className="text-xs font-medium text-ink">{t(`tool_${tool.id}`)}</p>
          <p className="text-2xs text-muted truncate" title={tool.detail??undefined}>{tool.available?t(`tool_${tool.id}_hint`,{target:tool.detail??''}):t(`tool_reason_${tool.reason}`)}</p>
        </div>
        <button className={button} disabled={!tool.available||!!starting} onClick={()=>void run(tool)}>
          {starting===tool.id?<IconSpinner className="w-3.5 h-3.5 animate-spin"/>:<IconPlay className="w-3 h-3"/>}{t('tool_run')}
        </button>
      </div>
    })}
  </section>
}
