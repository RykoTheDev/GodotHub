use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct RepoIdentity {
    pub common_dir: PathBuf,
    pub subpath: PathBuf,
}

#[derive(Debug, Clone)]
pub struct RepoLocation {
    pub identity: RepoIdentity,
    pub is_main_worktree: bool,
}

fn read_gitdir_pointer(dot_git: &Path, worktree_root: &Path) -> Option<PathBuf> {
    let content = fs::read_to_string(dot_git).ok()?;
    let target = content
        .lines()
        .find_map(|line| line.trim().strip_prefix("gitdir:"))?
        .trim();
    if target.is_empty() {
        return None;
    }
    let target = Path::new(target);
    let resolved = if target.is_absolute() {
        target.to_path_buf()
    } else {
        worktree_root.join(target)
    };
    fs::canonicalize(resolved).ok()
}

fn common_dir_of(git_dir: &Path) -> PathBuf {
    fs::read_to_string(git_dir.join("commondir"))
        .ok()
        .map(|raw| raw.trim().to_string())
        .filter(|raw| !raw.is_empty())
        .and_then(|raw| {
            let target = Path::new(&raw);
            let resolved = if target.is_absolute() {
                target.to_path_buf()
            } else {
                git_dir.join(target)
            };
            fs::canonicalize(resolved).ok()
        })
        .unwrap_or_else(|| git_dir.to_path_buf())
}

pub fn locate(project_dir: &Path) -> Option<RepoLocation> {
    let project_dir = fs::canonicalize(project_dir).ok()?;
    let mut current = project_dir.as_path();
    loop {
        let dot_git = current.join(".git");
        if dot_git.is_dir() {
            let common_dir = fs::canonicalize(&dot_git).ok()?;
            let subpath = project_dir.strip_prefix(current).ok()?.to_path_buf();
            return Some(RepoLocation {
                identity: RepoIdentity { common_dir, subpath },
                is_main_worktree: true,
            });
        }
        if dot_git.is_file() {
            let git_dir = read_gitdir_pointer(&dot_git, current)?;
            let common_dir = common_dir_of(&git_dir);
            let subpath = project_dir.strip_prefix(current).ok()?.to_path_buf();
            let is_main_worktree = common_dir == git_dir;
            return Some(RepoLocation {
                identity: RepoIdentity { common_dir, subpath },
                is_main_worktree,
            });
        }
        current = current.parent()?;
    }
}

pub fn identity(project_dir: &Path) -> Option<RepoIdentity> {
    locate(project_dir).map(|location| location.identity)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_root(name: &str) -> PathBuf {
        let root = std::env::temp_dir().join(format!(
            "godothub-repo-identity-{name}-{}",
            uuid::Uuid::new_v4()
        ));
        fs::create_dir_all(&root).unwrap();
        root
    }

    fn make_linked_worktree(main: &Path, linked: &Path, name: &str) {
        let admin = main.join(".git").join("worktrees").join(name);
        fs::create_dir_all(&admin).unwrap();
        fs::write(admin.join("commondir"), "../..\n").unwrap();
        fs::create_dir_all(linked).unwrap();
        fs::write(
            linked.join(".git"),
            format!("gitdir: {}\n", admin.to_string_lossy()),
        )
        .unwrap();
    }

    #[test]
    fn main_and_linked_worktrees_share_an_identity() {
        let root = temp_root("shared");
        let main = root.join("Game");
        fs::create_dir_all(main.join(".git")).unwrap();
        let linked = root.join("Game-worktree");
        make_linked_worktree(&main, &linked, "Game-worktree");

        let main_location = locate(&main).unwrap();
        let linked_location = locate(&linked).unwrap();
        assert!(main_location.is_main_worktree);
        assert!(!linked_location.is_main_worktree);
        assert_eq!(main_location.identity, linked_location.identity);

        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn subfolder_projects_stay_distinct_within_one_repo() {
        let root = temp_root("subfolders");
        let repo = root.join("Monorepo");
        fs::create_dir_all(repo.join(".git")).unwrap();
        fs::create_dir_all(repo.join("client")).unwrap();
        fs::create_dir_all(repo.join("server")).unwrap();

        assert_ne!(identity(&repo.join("client")), identity(&repo.join("server")));

        let linked = root.join("Monorepo-worktree");
        make_linked_worktree(&repo, &linked, "Monorepo-worktree");
        fs::create_dir_all(linked.join("client")).unwrap();
        assert_eq!(identity(&repo.join("client")), identity(&linked.join("client")));

        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn separate_repositories_differ() {
        let root = temp_root("separate");
        fs::create_dir_all(root.join("A").join(".git")).unwrap();
        fs::create_dir_all(root.join("B").join(".git")).unwrap();
        assert_ne!(identity(&root.join("A")), identity(&root.join("B")));
        fs::remove_dir_all(root).unwrap();
    }
}
