import { ProjectTile, type ProjectTileProps } from './ProjectTile'

export function ProjectCardGridItem(props: ProjectTileProps) {
  return <ProjectTile {...props} viewMode={props.viewMode ?? 'grid'} />
}
