use crate::persist;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

const GITHUB_DEV_CLIENT_ID: &str = "Ov23liu8vbSyRFgs0Ka0";
const GITLAB_DEV_CLIENT_ID: &str = "e80ad1fc408f647d60484286a65ae370bb7b06fdfd7fc5dc36478542f76529ee";

const GITHUB_SCOPES: &str = "repo read:user gist";
const GITLAB_SCOPES: &str = "read_repository write_repository read_user";

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct GitAuthFile {
    #[serde(default)]
    github: Option<GitAccount>,
    #[serde(default)]
    gitlab: Option<GitAccount>,
    #[serde(default)]
    pats: Vec<GitPat>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GitAccount {
    username: String,
    access_token: String,
    #[serde(default)]
    base_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GitPat {
    host: String,
    username: String,
    token: String,
}

#[derive(Serialize)]
pub struct GitAuthState {
    pub github: Option<GitAccountInfo>,
    pub gitlab: Option<GitAccountInfo>,
    pub pats: Vec<GitPatInfo>,
}

#[derive(Serialize)]
pub struct GitAccountInfo {
    pub username: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub host: Option<String>,
}

#[derive(Serialize)]
pub struct GitPatInfo {
    pub host: String,
    pub username: String,
}

#[derive(Serialize)]
pub struct DeviceFlowStart {
    pub provider: String,
    pub device_code: String,
    pub user_code: String,
    pub verification_uri: String,
    pub verification_uri_complete: String,
    pub interval: u64,
    pub expires_in: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub base_url: Option<String>,
}

#[derive(Serialize)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum DeviceFlowPoll {
    Pending,
    Success { username: String },
    Error { message: String },
}

fn auth_file(app: &AppHandle) -> PathBuf {
    let base = app.path().app_data_dir().expect("no app data dir");
    let _ = std::fs::create_dir_all(&base);
    base.join("git_auth.json")
}

pub fn credentials_store_file(app: &AppHandle) -> PathBuf {
    app.path()
        .app_data_dir()
        .expect("no app data dir")
        .join("git-credentials")
}

fn read_auth(app: &AppHandle) -> GitAuthFile {
    persist::read_json(&auth_file(app))
}

fn encode_userinfo(s: &str) -> String {
    let mut out = String::new();
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{:02X}", b)),
        }
    }
    out
}

fn host_from_base_url(base_url: &str) -> String {
    let trimmed = base_url.trim().trim_end_matches('/');
    let without_scheme = trimmed
        .trim_start_matches("https://")
        .trim_start_matches("http://");
    match without_scheme.find('/') {
        Some(i) => without_scheme[..i].to_string(),
        None => without_scheme.to_string(),
    }
}

fn rewrite_credentials_store(app: &AppHandle, auth: &GitAuthFile) {
    let mut lines: Vec<String> = Vec::new();
    if let Some(g) = &auth.github {
        lines.push(format!(
            "https://oauth2:{}@github.com",
            encode_userinfo(&g.access_token)
        ));
    }
    if let Some(g) = &auth.gitlab {
        let host = g
            .base_url
            .as_deref()
            .map(host_from_base_url)
            .filter(|h| !h.is_empty())
            .unwrap_or_else(|| "gitlab.com".to_string());
        lines.push(format!(
            "https://oauth2:{}@{}",
            encode_userinfo(&g.access_token),
            host
        ));
    }
    for p in &auth.pats {
        lines.push(format!(
            "https://{}:{}@{}",
            encode_userinfo(&p.username),
            encode_userinfo(&p.token),
            p.host
        ));
    }
    let _ = std::fs::write(credentials_store_file(app), lines.join("\n"));
}

fn write_auth(app: &AppHandle, auth: &GitAuthFile) -> Result<(), String> {
    persist::write_json(&auth_file(app), auth).map_err(|e| e.to_string())?;
    rewrite_credentials_store(app, auth);
    Ok(())
}

fn github_client_id() -> Option<String> {
    if let Ok(v) = std::env::var("GODOTHUB_GITHUB_CLIENT_ID") {
        let v = v.trim().to_string();
        if !v.is_empty() {
            return Some(v);
        }
    }
    let v = GITHUB_DEV_CLIENT_ID.trim();
    if !v.is_empty() && !v.starts_with("YOUR_") {
        return Some(v.to_string());
    }
    None
}

fn gitlab_client_id() -> Option<String> {
    if let Ok(v) = std::env::var("GODOTHUB_GITLAB_CLIENT_ID") {
        let v = v.trim().to_string();
        if !v.is_empty() {
            return Some(v);
        }
    }
    let v = GITLAB_DEV_CLIENT_ID.trim();
    if !v.is_empty() && !v.starts_with("YOUR_") {
        return Some(v.to_string());
    }
    None
}

fn normalize_gitlab_base_url(base_url: &str) -> String {
    let trimmed = base_url.trim().trim_end_matches('/');
    if trimmed.is_empty() {
        return String::new();
    }
    if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        return trimmed.to_string();
    }
    format!("https://{}", trimmed)
}

#[tauri::command]
pub async fn start_device_flow(
    app: AppHandle,
    provider: String,
    base_url: Option<String>,
    client_id: Option<String>,
) -> Result<DeviceFlowStart, String> {
    let _ = &app;
    let (client_id, device_url, scopes, effective_base_url) = match provider.as_str() {
        "github" => (
            github_client_id().ok_or_else(|| {
                "GitHub OAuth isn't configured. Set the GODOTHUB_GITHUB_CLIENT_ID \
                 environment variable."
                    .to_string()
            })?,
            "https://github.com/login/device/code".to_string(),
            GITHUB_SCOPES.to_string(),
            None,
        ),
        "gitlab" => {
            let base = normalize_gitlab_base_url(base_url.as_deref().unwrap_or(""));
            let client_id = if !base.is_empty() {
                client_id
                    .map(|c| c.trim().to_string())
                    .filter(|c| !c.is_empty())
                    .ok_or_else(|| {
                        "Signing in to a self-hosted GitLab instance requires its \
                         OAuth Application ID (Client ID).".to_string()
                    })?
            } else {
                gitlab_client_id().ok_or_else(|| {
                    "GitLab OAuth isn't configured. Set the GODOTHUB_GITLAB_CLIENT_ID \
                     environment variable."
                        .to_string()
                })?
            };
            let device_url = if base.is_empty() {
                "https://gitlab.com/oauth/authorize_device".to_string()
            } else {
                format!("{}/oauth/authorize_device", base)
            };
            (
                client_id,
                device_url,
                GITLAB_SCOPES.to_string(),
                if base.is_empty() { None } else { Some(base) },
            )
        }
        _ => return Err(format!("Unknown provider: {}", provider)),
    };

    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())?;

    let body = url::form_urlencoded::Serializer::new(String::new())
        .append_pair("client_id", &client_id)
        .append_pair("scope", &scopes)
        .finish();
    let resp = client
        .post(&device_url)
        .header("Accept", "application/json")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(body)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        if let Ok(v) = serde_json::from_str::<serde_json::Value>(&body) {
            if v["error"] == "invalid_scope" {
                return Err(
                    "GitLab rejected the requested scopes. Open your OAuth \
                     application on GitLab (Preferences -> Applications) and \
                     enable all of: read_repository, write_repository, read_user. \
                     Then try signing in again."
                        .to_string(),
                );
            }
        }
        return Err(format!(
            "Device authorization request failed ({}). {}",
            status,
            body.trim()
        ));
    }

    let json: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("Couldn't parse device authorization response: {}", e))?;

    let make_absolute = |uri: &str| -> String {
        let uri = uri.trim();
        if uri.is_empty() || uri.starts_with("http://") || uri.starts_with("https://") {
            return uri.to_string();
        }
        match &effective_base_url {
            Some(base) if uri.starts_with('/') => format!("{}{}", base, uri),
            _ => uri.to_string(),
        }
    };

    Ok(DeviceFlowStart {
        provider: provider.clone(),
        device_code: json["device_code"]
            .as_str()
            .ok_or("Response missing device_code")?
            .to_string(),
        user_code: json["user_code"]
            .as_str()
            .ok_or("Response missing user_code")?
            .to_string(),
        verification_uri: make_absolute(
            json["verification_uri"].as_str().unwrap_or(""),
        ),
        verification_uri_complete: make_absolute(
            json["verification_uri_complete"].as_str().unwrap_or(""),
        ),
        interval: json["interval"].as_u64().unwrap_or(5).max(1),
        expires_in: json["expires_in"].as_u64().unwrap_or(1800),
        base_url: effective_base_url,
    })
}

#[tauri::command]
pub async fn poll_device_flow(
    app: AppHandle,
    provider: String,
    device_code: String,
    base_url: Option<String>,
    client_id: Option<String>,
) -> Result<DeviceFlowPoll, String> {
    let (client_id, token_url, user_url, username_field, effective_base_url) =
        match provider.as_str() {
            "github" => (
                github_client_id().ok_or("GitHub OAuth isn't configured")?,
                "https://github.com/login/oauth/access_token".to_string(),
                "https://api.github.com/user".to_string(),
                "login",
                None,
            ),
            "gitlab" => {
                let base = normalize_gitlab_base_url(base_url.as_deref().unwrap_or(""));
                let client_id = if !base.is_empty() {
                    client_id
                        .map(|c| c.trim().to_string())
                        .filter(|c| !c.is_empty())
                        .ok_or_else(|| {
                            "Signing in to a self-hosted GitLab instance requires its \
                             OAuth Application ID (Client ID).".to_string()
                        })?
                } else {
                    gitlab_client_id().ok_or_else(|| {
                        "GitLab OAuth isn't configured. Set the GODOTHUB_GITLAB_CLIENT_ID \
                         environment variable."
                            .to_string()
                    })?
                };
                let (token_url, user_url) = if base.is_empty() {
                    (
                        "https://gitlab.com/oauth/token".to_string(),
                        "https://gitlab.com/api/v4/user".to_string(),
                    )
                } else {
                    (
                        format!("{}/oauth/token", base),
                        format!("{}/api/v4/user", base),
                    )
                };
                (
                    client_id,
                    token_url,
                    user_url,
                    "username",
                    if base.is_empty() { None } else { Some(base) },
                )
            }
            _ => return Err(format!("Unknown provider: {}", provider)),
        };

    let client = reqwest::Client::builder()
        .user_agent("godot-hub")
        .build()
        .map_err(|e| e.to_string())?;

    let body = url::form_urlencoded::Serializer::new(String::new())
        .append_pair("client_id", &client_id)
        .append_pair("device_code", &device_code)
        .append_pair(
            "grant_type",
            "urn:ietf:params:oauth:grant-type:device_code",
        )
        .finish();
    let resp = client
        .post(&token_url)
        .header("Accept", "application/json")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(body)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let json: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;

    if let Some(err) = json["error"].as_str() {
        return Ok(match err {
            "authorization_pending" | "slow_down" => DeviceFlowPoll::Pending,
            "access_denied" => DeviceFlowPoll::Error {
                message: "You denied the authorization request.".into(),
            },
            "expired_token" => DeviceFlowPoll::Error {
                message: "The code expired. Start over and try again.".into(),
            },
            other => DeviceFlowPoll::Error {
                message: other.to_string(),
            },
        });
    }

    let access_token = json["access_token"]
        .as_str()
        .ok_or("Response missing access_token")?
        .to_string();

    let user = client
        .get(&user_url)
        .header("Authorization", format!("Bearer {}", access_token))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let user_json: serde_json::Value = user.json().await.map_err(|e| e.to_string())?;
    let username = user_json[username_field]
        .as_str()
        .unwrap_or("user")
        .to_string();

    let mut auth = read_auth(&app);
    match provider.as_str() {
        "github" => {
            auth.github = Some(GitAccount {
                username: username.clone(),
                access_token,
                base_url: None,
            })
        }
        "gitlab" => {
            auth.gitlab = Some(GitAccount {
                username: username.clone(),
                access_token,
                base_url: effective_base_url,
            })
        }
        _ => return Err(format!("Unknown provider: {}", provider)),
    }
    write_auth(&app, &auth)?;

    Ok(DeviceFlowPoll::Success { username })
}

#[tauri::command]
pub fn get_git_auth_state(app: AppHandle) -> GitAuthState {
    let auth = read_auth(&app);
    GitAuthState {
        github: auth
            .github
            .as_ref()
            .map(|a| GitAccountInfo {
                username: a.username.clone(),
                host: None,
            }),
        gitlab: auth
            .gitlab
            .as_ref()
            .map(|a| GitAccountInfo {
                username: a.username.clone(),
                host: a
                    .base_url
                    .as_deref()
                    .map(host_from_base_url)
                    .filter(|h| !h.is_empty()),
            }),
        pats: auth
            .pats
            .iter()
            .map(|p| GitPatInfo {
                host: p.host.clone(),
                username: p.username.clone(),
            })
            .collect(),
    }
}

#[tauri::command]
pub fn disconnect_git_auth(app: AppHandle, provider: String) -> Result<(), String> {
    let mut auth = read_auth(&app);
    match provider.as_str() {
        "github" => auth.github = None,
        "gitlab" => auth.gitlab = None,
        _ => return Err(format!("Unknown provider: {}", provider)),
    }
    write_auth(&app, &auth)
}

#[tauri::command]
pub fn save_git_pat(
    app: AppHandle,
    host: String,
    username: String,
    token: String,
) -> Result<(), String> {
    let host = host
        .trim()
        .to_lowercase()
        .trim_start_matches("https://")
        .trim_start_matches("http://")
        .trim_end_matches('/')
        .to_string();
    if host.is_empty() {
        return Err("Host can't be empty".into());
    }
    if username.trim().is_empty() || token.trim().is_empty() {
        return Err("Username and token are required".into());
    }
    let mut auth = read_auth(&app);
    if let Some(p) = auth.pats.iter_mut().find(|p| p.host.eq_ignore_ascii_case(&host)) {
        p.username = username.trim().to_string();
        p.token = token.trim().to_string();
    } else {
        auth.pats.push(GitPat {
            host,
            username: username.trim().to_string(),
            token: token.trim().to_string(),
        });
    }
    write_auth(&app, &auth)
}

#[tauri::command]
pub fn remove_git_pat(app: AppHandle, host: String) -> Result<(), String> {
    let mut auth = read_auth(&app);
    auth.pats.retain(|p| !p.host.eq_ignore_ascii_case(host.trim()));
    write_auth(&app, &auth)
}

pub fn github_oauth_token(app: &AppHandle) -> Option<String> {
    read_auth(app).github.map(|a| a.access_token)
}

pub fn gitlab_oauth_info(app: &AppHandle) -> Option<(String, String)> {
    read_auth(app).gitlab.map(|a| {
        let base = a
            .base_url
            .clone()
            .unwrap_or_else(|| "https://gitlab.com".to_string());
        (a.access_token, base)
    })
}

fn repo_slug(name: &str) -> String {
    let mut out = String::new();
    let mut prev_dash = false;
    for c in name.trim().to_lowercase().chars() {
        let ok = c.is_ascii_alphanumeric() || matches!(c, '-' | '_' | '.');
        if ok {
            out.push(c);
            prev_dash = false;
        } else if !prev_dash && !out.is_empty() {
            out.push('-');
            prev_dash = true;
        }
    }
    out.trim_end_matches('-').to_string()
}

#[derive(Serialize)]
pub struct CreateRepoResult {
    pub url: String,
    pub slug: String,
}

#[derive(Serialize, Deserialize)]
pub struct UserRepoInfo {
    pub name: String,
    pub full_name: String,
    pub description: Option<String>,
    pub clone_url: String,
    pub html_url: String,
    pub private: bool,
    pub language: Option<String>,
    pub default_branch: Option<String>,
}

#[derive(Serialize)]
pub struct UserRepoPage {
    pub repos: Vec<UserRepoInfo>,
    pub has_more: bool,
}

const REPOS_PER_PAGE: u32 = 30;

#[tauri::command]
pub async fn list_user_repos(
    app: AppHandle,
    provider: String,
    page: u32,
) -> Result<UserRepoPage, String> {
    let client = reqwest::Client::builder()
        .user_agent("godot-hub/1.0")
        .build()
        .map_err(|e| e.to_string())?;

    match provider.as_str() {
        "github" => {
            let token = github_oauth_token(&app)
                .ok_or("Sign in with GitHub first (Integrations > Git)")?;
            let url = format!(
                "https://api.github.com/user/repos?per_page={}&sort=updated&page={}&type=all",
                REPOS_PER_PAGE, page
            );
            let resp = client
                .get(&url)
                .header("Accept", "application/vnd.github+json")
                .header("Authorization", format!("Bearer {}", token))
                .send()
                .await
                .map_err(|e| e.to_string())?;
            if !resp.status().is_success() {
                return Err(format!(
                    "GitHub API error ({}).",
                    resp.status()
                ));
            }
            let repos: Vec<serde_json::Value> =
                resp.json().await.map_err(|e| e.to_string())?;
            let has_more = repos.len() >= REPOS_PER_PAGE as usize;
            let items: Vec<UserRepoInfo> = repos.iter().map(|r| UserRepoInfo {
                name: r["name"].as_str().unwrap_or("").to_string(),
                full_name: r["full_name"].as_str().unwrap_or("").to_string(),
                description: r["description"].as_str().map(|s| s.to_string()),
                clone_url: r["clone_url"].as_str().unwrap_or("").to_string(),
                html_url: r["html_url"].as_str().unwrap_or("").to_string(),
                private: r["private"].as_bool().unwrap_or(false),
                language: r["language"].as_str().map(|s| s.to_string()),
                default_branch: r["default_branch"].as_str().map(|s| s.to_string()),
            }).collect();
            Ok(UserRepoPage { repos: items, has_more })
        }
        "gitlab" => {
            let (token, base) = gitlab_oauth_info(&app)
                .ok_or("Sign in with GitLab first (Integrations > Git)")?;
            let api_base = base.trim_end_matches('/');
            let url = format!(
                "{}/api/v4/projects?membership=true&order_by=updated_at&sort=desc&per_page={}&page={}",
                api_base, REPOS_PER_PAGE, page
            );
            let resp = client
                .get(&url)
                .header("Authorization", format!("Bearer {}", token))
                .send()
                .await
                .map_err(|e| e.to_string())?;
            if !resp.status().is_success() {
                return Err(format!(
                    "GitLab API error ({}).",
                    resp.status()
                ));
            }
            let repos: Vec<serde_json::Value> =
                resp.json().await.map_err(|e| e.to_string())?;
            let has_more = repos.len() >= REPOS_PER_PAGE as usize;
            let items: Vec<UserRepoInfo> = repos.iter().map(|r| {
                let path = r["path_with_namespace"].as_str().unwrap_or("");
                let clone_url = r["http_url_to_repo"].as_str().unwrap_or("").to_string();
                let web_url = r["web_url"].as_str().unwrap_or("").to_string();
                let is_private = r["visibility"].as_str() == Some("private")
                    || r["visibility"].as_str() == Some("internal");
                UserRepoInfo {
                    name: r["name"].as_str().unwrap_or("").to_string(),
                    full_name: path.to_string(),
                    description: r["description"].as_str().filter(|s| !s.is_empty()).map(|s| s.to_string()),
                    clone_url,
                    html_url: web_url,
                    private: is_private,
                    language: r["language"].as_str().map(|s| s.to_string()),
                    default_branch: r["default_branch"].as_str().map(|s| s.to_string()),
                }
            }).collect();
            Ok(UserRepoPage { repos: items, has_more })
        }
        _ => Err(format!("Unknown provider: {}", provider)),
    }
}

#[tauri::command]
pub async fn create_remote_repo(
    app: AppHandle,
    provider: String,
    name: String,
    private_repo: bool,
    path: String,
) -> Result<CreateRepoResult, String> {
    let slug = repo_slug(&name);
    if slug.is_empty() {
        return Err("Repository name is empty after cleaning".into());
    }

    let client = reqwest::Client::builder()
        .user_agent("godot-hub/1.0")
        .build()
        .map_err(|e| e.to_string())?;

    let (repo_url, token, api_base) = match provider.as_str() {
        "github" => {
            let token = github_oauth_token(&app)
                .ok_or("Sign in with GitHub first (Integrations > Git)")?;
            let body = serde_json::json!({
                "name": slug,
                "private": private_repo,
                "description": "Created with GodotHub",
            });
            let resp = client
                .post("https://api.github.com/user/repos")
                .header("Accept", "application/vnd.github+json")
                .header("Authorization", format!("Bearer {}", token))
                .header("Content-Type", "application/json")
                .body(body.to_string())
                .send()
                .await
                .map_err(|e| e.to_string())?;
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            if !status.is_success() {
                return Err(format!(
                    "GitHub failed to create the repository ({}). {}",
                    status,
                    text.trim()
                ));
            }
            let json: serde_json::Value =
                serde_json::from_str(&text).map_err(|e| e.to_string())?;
            let url = json["clone_url"]
                .as_str()
                .ok_or("GitHub response missing clone_url")?
                .to_string();
            (url, token, String::new())
        }
        "gitlab" => {
            let (token, base) = gitlab_oauth_info(&app)
                .ok_or("Sign in with GitLab first (Integrations > Git)")?;
            let visibility = if private_repo { "private" } else { "public" };
            let body = url::form_urlencoded::Serializer::new(String::new())
                .append_pair("name", &slug)
                .append_pair("path", &slug)
                .append_pair("visibility", visibility)
                .append_pair("initialize_with_readme", "false")
                .finish();
            let api = format!("{}/api/v4/projects", base.trim_end_matches('/'));
            let resp = client
                .post(&api)
                .header("Authorization", format!("Bearer {}", token))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .body(body)
                .send()
                .await
                .map_err(|e| e.to_string())?;
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            if !status.is_success() {
                return Err(format!(
                    "GitLab failed to create the project ({}). {}",
                    status,
                    text.trim()
                ));
            }
            let json: serde_json::Value =
                serde_json::from_str(&text).map_err(|e| e.to_string())?;
            let url = json["http_url_to_repo"]
                .as_str()
                .ok_or("GitLab response missing http_url_to_repo")?
                .to_string();
            (url, token, base)
        }
        _ => return Err(format!("Unknown provider: {}", provider)),
    };

    let _ = token;
    let _ = api_base;
    let path2 = path.clone();
    let repo_url2 = repo_url.clone();
    tokio::task::spawn_blocking(move || {
        let remotes = crate::git_helpers::git_cmd(&path2, ["remote"]).unwrap_or_default();
        let has_origin = remotes.lines().any(|l| l.trim() == "origin");
        let verb = if has_origin { "set-url" } else { "add" };
        crate::git_helpers::git_cmd(&path2, ["remote", verb, "origin", &repo_url2])
            .map_err(|e| e.to_string())?;

        let branch = crate::git_helpers::git_cmd(&path2, ["rev-parse", "--abbrev-ref", "HEAD"])
            .unwrap_or_else(|_| "main".to_string())
            .trim()
            .to_string();
        crate::git_helpers::git_cmd(&path2, ["push", "-u", "origin", &branch])
            .map_err(|e| e.to_string())
    })
    .await
    .map_err(|e| e.to_string())??;

    Ok(CreateRepoResult { url: repo_url, slug })
}
