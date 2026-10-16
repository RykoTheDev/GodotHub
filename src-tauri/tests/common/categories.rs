use super::best_folder_match;

fn assignments() -> Vec<(String, String)> {
    vec![
        ("Mine".to_string(), "Projects".to_string()),
        ("External".to_string(), "Other People's Projects".to_string()),
        ("Archive".to_string(), "Projects/Archive".to_string()),
    ]
}

#[test]
fn a_project_inside_a_folder_inherits_its_category() {
    assert_eq!(
        best_folder_match(&assignments(), "Projects/My Game").as_deref(),
        Some("Mine")
    );
    assert_eq!(
        best_folder_match(&assignments(), "Other People's Projects/Clone").as_deref(),
        Some("External")
    );
}

#[test]
fn a_project_deep_inside_a_folder_still_matches() {
    assert_eq!(
        best_folder_match(&assignments(), "Other People's Projects/2026/Jam/Game").as_deref(),
        Some("External")
    );
}

#[test]
fn the_folder_itself_matches_its_category() {
    assert_eq!(
        best_folder_match(&assignments(), "Projects").as_deref(),
        Some("Mine")
    );
}

#[test]
fn the_most_specific_nested_folder_wins() {
    assert_eq!(
        best_folder_match(&assignments(), "Projects/Archive/Old Game").as_deref(),
        Some("Archive")
    );
    assert_eq!(
        best_folder_match(&assignments(), "Projects/New Game").as_deref(),
        Some("Mine")
    );
}

#[test]
fn lookalike_folder_names_do_not_match() {
    assert_eq!(best_folder_match(&assignments(), "ProjectsExtra/Game"), None);
    assert_eq!(best_folder_match(&assignments(), "Other Projects/Game"), None);
}

#[test]
fn paths_outside_all_assigned_folders_have_no_category() {
    assert_eq!(best_folder_match(&assignments(), "Elsewhere/Game"), None);
}

#[test]
fn separators_and_trailing_slashes_are_normalized() {
    let assignments = vec![("Mine".to_string(), "Projects/".to_string())];
    assert_eq!(
        best_folder_match(&assignments, "Projects\\Game").as_deref(),
        Some("Mine")
    );
    assert_eq!(
        best_folder_match(&assignments, "Projects").as_deref(),
        Some("Mine")
    );
}

#[test]
fn an_empty_assignment_list_never_matches() {
    assert_eq!(best_folder_match(&[], "Projects/Game"), None);
}
