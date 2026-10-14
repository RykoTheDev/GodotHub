use super::*;
use std::process::Command;

struct Fixture {
    root: PathBuf,
    repo: PathBuf,
}

impl Fixture {
    fn new() -> Self {
        let root = std::env::temp_dir().join(format!(
            "godothub-worktrees-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let repo = root.join("repo");
        fs::create_dir_all(&repo).unwrap();
        let fixture = Self { root, repo };
        fixture.git(&["init", "-b", "main"]);
        fixture.git(&["config", "user.email", "worktree-test@example.invalid"]);
        fixture.git(&["config", "user.name", "Worktree test"]);
        fs::write(
            fixture.repo.join("project.godot"),
            "[application]\nconfig/name=\"Worktree test\"\n",
        )
        .unwrap();
        fixture.git(&["add", "."]);
        fixture.git(&["commit", "-m", "Fixture"]);
        fixture
    }
    fn path(&self) -> String {
        self.repo.to_string_lossy().into_owned()
    }
    fn git(&self, args: &[&str]) {
        let output = Command::new("git")
            .arg("-C")
            .arg(&self.repo)
            .args(args)
            .output()
            .unwrap();
        assert!(
            output.status.success(),
            "{}",
            String::from_utf8_lossy(&output.stderr)
        );
    }
}
impl Drop for Fixture {
    fn drop(&mut self) {
        assert!(self.root.starts_with(std::env::temp_dir()));
        assert!(self
            .root
            .file_name()
            .unwrap()
            .to_string_lossy()
            .starts_with("godothub-worktrees-"));
        let _ = fs::remove_dir_all(&self.root);
    }
}

#[test]
fn creation_supports_relative_paths_and_identifies_main() {
    let f = Fixture::new();
    tokio::runtime::Runtime::new().unwrap().block_on(async {
        git_worktree_add(f.path(), "../feature space".into(), Some("feature".into()))
            .await
            .unwrap();
        let worktrees = git_worktree_list(f.path()).await.unwrap();
        assert_eq!(worktrees.len(), 2);
        assert!(worktrees[0].is_main);
        assert!(!worktrees[1].is_main);
        assert_eq!(worktrees[1].branch.as_deref(), Some("feature"));
        git_worktree_switch(f.path(), worktrees[1].path.clone())
            .await
            .unwrap();
        assert!(git_worktree_remove(
            worktrees[1].path.clone(),
            worktrees[1].path.clone(),
            Some(true)
        )
        .await
        .is_err());
    });
}

#[test]
fn dirty_worktree_requires_explicit_force_and_keeps_branch() {
    let f = Fixture::new();
    let linked = f.root.join("dirty");
    let linked_path = linked.to_string_lossy().into_owned();
    tokio::runtime::Runtime::new().unwrap().block_on(async {
        git_worktree_add(f.path(), linked_path.clone(), Some("dirty".into()))
            .await
            .unwrap();
        fs::write(linked.join("uncommitted.txt"), "Do not lose this").unwrap();
        assert!(git_worktree_remove(f.path(), linked_path.clone(), None)
            .await
            .is_err());
        assert!(linked.join("uncommitted.txt").exists());
        git_worktree_remove(f.path(), linked_path, Some(true))
            .await
            .unwrap();
        assert!(!linked.exists());
        f.git(&["show-ref", "--verify", "refs/heads/dirty"]);
    });
}

#[test]
fn switching_rejects_an_unrelated_repository() {
    let a = Fixture::new();
    let b = Fixture::new();
    tokio::runtime::Runtime::new().unwrap().block_on(async {
        assert!(git_worktree_switch(a.path(), b.path()).await.is_err());
    });
}

#[test]
fn legacy_experimental_flag_is_ignored_when_loading_settings() {
    let mut value = serde_json::to_value(crate::models::AppSettings::default()).unwrap();
    value["git_worktrees_enabled"] = serde_json::json!(false);
    let settings: crate::models::AppSettings = serde_json::from_value(value).unwrap();
    assert!(serde_json::to_value(settings)
        .unwrap()
        .get("git_worktrees_enabled")
        .is_none());
}
