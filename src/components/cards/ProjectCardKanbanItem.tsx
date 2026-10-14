import { ProjectTile, type ProjectTileProps } from './ProjectTile'

export function ProjectCardKanbanItem(props: ProjectTileProps) {
  return <ProjectTile {...props} viewMode={props.viewMode ?? 'kanban'} />
}
