import { withStableCallbacks } from '../../lib/stableCallbacks'
import { ProjectTile, type ProjectTileProps } from './ProjectTile'

function ProjectCardGridItemInner(props: ProjectTileProps) {
  return <ProjectTile {...props} viewMode={props.viewMode ?? 'grid'} />
}

export const ProjectCardGridItem = withStableCallbacks(ProjectCardGridItemInner)
