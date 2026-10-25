import { withStableCallbacks } from '../../lib/stableCallbacks'
import { ProjectTile, type ProjectTileProps } from './ProjectTile'

function ProjectCardKanbanItemInner(props: ProjectTileProps) {
  return <ProjectTile {...props} viewMode={props.viewMode ?? 'kanban'} />
}

export const ProjectCardKanbanItem = withStableCallbacks(ProjectCardKanbanItemInner)
