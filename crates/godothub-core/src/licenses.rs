pub fn license_text(id: &str, project_name: &str) -> Option<String> {
    let raw = match id {
        "MIT" => include_str!("../assets/project-licenses/mit.txt"),
        "Apache-2.0" => include_str!("../assets/project-licenses/apache-2.0.txt"),
        "GPL-3.0" => include_str!("../assets/project-licenses/gpl-3.0.txt"),
        "Unlicense" => include_str!("../assets/project-licenses/unlicense.txt"),
        _ => return None,
    };
    let year = chrono::Utc::now().format("%Y").to_string();
    Some(
        raw.replace("[year]", &year)
            .replace("[copyright holder]", project_name)
            .replace("[name of copyright owner]", project_name)
            .replace("<name of author>", project_name),
    )
}
