use super::parse_path_arg;

#[test]
fn parses_quoted_project_path() {
    assert_eq!(
        parse_path_arg(r#"Godot_v4.exe --path "D:\Game Projects\Demo" --editor"#),
        Some(r#"D:\Game Projects\Demo"#.to_string())
    );
}

#[test]
fn parses_unquoted_project_path() {
    assert_eq!(
        parse_path_arg(r#"Godot_v4.exe --path D:\Demo --editor"#),
        Some(r#"D:\Demo"#.to_string())
    );
}

#[test]
fn parses_equals_project_path() {
    assert_eq!(
        parse_path_arg(r#"Godot_v4.exe --path="D:\Game Projects\Demo" --editor"#),
        Some(r#"D:\Game Projects\Demo"#.to_string())
    );
}

#[test]
fn ignores_path_like_argument_names() {
    assert_eq!(parse_path_arg("Godot_v4.exe --pathology D:\\Nope"), None);
}
