use crate::persist;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use crate::AppHandle;

const GITHUB_DEV_CLIENT_ID: &str = "Ov23liu8vbSyRFgs0Ka0";
const GITLAB_DEV_CLIENT_ID: &str =
    "e80ad1fc408f647d60484286a65ae370bb7b06fdfd7fc5dc36478542f76529ee";

const GITHUB_SCOPES: &str = "repo read:user gist";
const GITLAB_SCOPES: &str = "api read_user";

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

fn rewrite_credentials_store(app: &AppHandle, auth: &GitAuthFile) -> Result<(), String> {
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
    persist::write_private_bytes(&credentials_store_file(app), lines.join("\n").as_bytes())
        .map_err(|e| format!("Could not save git credentials: {e}"))
}

fn write_auth(app: &AppHandle, auth: &GitAuthFile) -> Result<(), String> {
    persist::write_json_private(&auth_file(app), auth).map_err(|e| e.to_string())?;
    rewrite_credentials_store(app, auth)
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
                         OAuth Application ID (Client ID)."
                            .to_string()
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

    let client = crate::http::client()?;

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
                return Err("GitLab rejected the requested scopes. Open your OAuth \
                     application on GitLab (Preferences -> Applications) and \
                     enable the 'api' and 'read_user' scopes. \
                     Then try signing in again."
                    .to_string());
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
        verification_uri: make_absolute(json["verification_uri"].as_str().unwrap_or("")),
        verification_uri_complete: make_absolute(
            json["verification_uri_complete"].as_str().unwrap_or(""),
        ),
        interval: json["interval"].as_u64().unwrap_or(5).max(1),
        expires_in: json["expires_in"].as_u64().unwrap_or(1800),
        base_url: effective_base_url,
    })
}

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
                             OAuth Application ID (Client ID)."
                                .to_string()
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

    let client = crate::http::client()?;

    let body = url::form_urlencoded::Serializer::new(String::new())
        .append_pair("client_id", &client_id)
        .append_pair("device_code", &device_code)
        .append_pair("grant_type", "urn:ietf:params:oauth:grant-type:device_code")
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

pub fn get_git_auth_state(app: AppHandle) -> GitAuthState {
    let auth = read_auth(&app);
    GitAuthState {
        github: auth.github.as_ref().map(|a| GitAccountInfo {
            username: a.username.clone(),
            host: None,
        }),
        gitlab: auth.gitlab.as_ref().map(|a| GitAccountInfo {
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

pub fn disconnect_git_auth(app: AppHandle, provider: String) -> Result<(), String> {
    let mut auth = read_auth(&app);
    match provider.as_str() {
        "github" => auth.github = None,
        "gitlab" => auth.gitlab = None,
        _ => return Err(format!("Unknown provider: {}", provider)),
    }
    write_auth(&app, &auth)
}

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
    if let Some(p) = auth
        .pats
        .iter_mut()
        .find(|p| p.host.eq_ignore_ascii_case(&host))
    {
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

pub fn remove_git_pat(app: AppHandle, host: String) -> Result<(), String> {
    let mut auth = read_auth(&app);
    auth.pats
        .retain(|p| !p.host.eq_ignore_ascii_case(host.trim()));
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

pub async fn list_user_repos(
    app: AppHandle,
    provider: String,
    page: u32,
) -> Result<UserRepoPage, String> {
    let client = crate::http::client()?;

    match provider.as_str() {
        "github" => {
            let token =
                github_oauth_token(&app).ok_or("Sign in with GitHub first (Integrations > Git)")?;
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
                return Err(format!("GitHub API error ({}).", resp.status()));
            }
            let repos: Vec<serde_json::Value> = resp.json().await.map_err(|e| e.to_string())?;
            let has_more = repos.len() >= REPOS_PER_PAGE as usize;
            let items: Vec<UserRepoInfo> = repos
                .iter()
                .map(|r| UserRepoInfo {
                    name: r["name"].as_str().unwrap_or("").to_string(),
                    full_name: r["full_name"].as_str().unwrap_or("").to_string(),
                    description: r["description"].as_str().map(|s| s.to_string()),
                    clone_url: r["clone_url"].as_str().unwrap_or("").to_string(),
                    html_url: r["html_url"].as_str().unwrap_or("").to_string(),
                    private: r["private"].as_bool().unwrap_or(false),
                    language: r["language"].as_str().map(|s| s.to_string()),
                    default_branch: r["default_branch"].as_str().map(|s| s.to_string()),
                })
                .collect();
            Ok(UserRepoPage {
                repos: items,
                has_more,
            })
        }
        "gitlab" => {
            let (token, base) =
                gitlab_oauth_info(&app).ok_or("Sign in with GitLab first (Integrations > Git)")?;
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
                return Err(format!("GitLab API error ({}).", resp.status()));
            }
            let repos: Vec<serde_json::Value> = resp.json().await.map_err(|e| e.to_string())?;
            let has_more = repos.len() >= REPOS_PER_PAGE as usize;
            let items: Vec<UserRepoInfo> = repos
                .iter()
                .map(|r| {
                    let path = r["path_with_namespace"].as_str().unwrap_or("");
                    let clone_url = r["http_url_to_repo"].as_str().unwrap_or("").to_string();
                    let web_url = r["web_url"].as_str().unwrap_or("").to_string();
                    let is_private = r["visibility"].as_str() == Some("private")
                        || r["visibility"].as_str() == Some("internal");
                    UserRepoInfo {
                        name: r["name"].as_str().unwrap_or("").to_string(),
                        full_name: path.to_string(),
                        description: r["description"]
                            .as_str()
                            .filter(|s| !s.is_empty())
                            .map(|s| s.to_string()),
                        clone_url,
                        html_url: web_url,
                        private: is_private,
                        language: r["language"].as_str().map(|s| s.to_string()),
                        default_branch: r["default_branch"].as_str().map(|s| s.to_string()),
                    }
                })
                .collect();
            Ok(UserRepoPage {
                repos: items,
                has_more,
            })
        }
        _ => Err(format!("Unknown provider: {}", provider)),
    }
}

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

    let client = crate::http::client()?;

    let (repo_url, token, api_base) = match provider.as_str() {
        "github" => {
            let token =
                github_oauth_token(&app).ok_or("Sign in with GitHub first (Integrations > Git)")?;
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
            let json: serde_json::Value = serde_json::from_str(&text).map_err(|e| e.to_string())?;
            let url = json["clone_url"]
                .as_str()
                .ok_or("GitHub response missing clone_url")?
                .to_string();
            (url, token, String::new())
        }
        "gitlab" => {
            let (token, base) =
                gitlab_oauth_info(&app).ok_or("Sign in with GitLab first (Integrations > Git)")?;
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
            let json: serde_json::Value = serde_json::from_str(&text).map_err(|e| e.to_string())?;
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

    Ok(CreateRepoResult {
        url: repo_url,
        slug,
    })
}

enum RemoteHost {
    GitHub,
    GitLab { api_base: String, token: Option<String> },
    Other,
}

struct RemoteRepo {
    web_url: String,
    repo_path: String,
    branch: String,
}

fn encode_component(s: &str) -> String {
    url::form_urlencoded::byte_serialize(s.as_bytes()).collect()
}

fn resolve_remote_repo(path: &str, local_branch: Option<&str>) -> Option<RemoteRepo> {
    let git = |args: &[&str]| {
        crate::git_helpers::git_cmd(path, args)
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
    };
    let branch = match local_branch {
        Some(b) => b.to_string(),
        None => git(&["rev-parse", "--abbrev-ref", "HEAD"]).filter(|b| b != "HEAD")?,
    };
    let remote = git(&["config", &format!("branch.{branch}.remote")]).or_else(|| {
        let remotes = git(&["remote"])?;
        let names: Vec<&str> = remotes.lines().map(str::trim).collect();
        names
            .iter()
            .find(|r| **r == "origin")
            .or_else(|| names.first())
            .map(|r| r.to_string())
    })?;
    let url = git(&["remote", "get-url", &remote])?;
    let remote_branch = git(&["config", &format!("branch.{branch}.merge")])
        .and_then(|m| m.strip_prefix("refs/heads/").map(str::to_string))
        .unwrap_or(branch);
    let web_url = crate::git::to_web_url(&url);
    let (scheme, rest) = web_url.split_once("://")?;
    let (authority, repo_path) = rest.split_once('/')?;
    let host = authority.rsplit_once('@').map(|(_, h)| h).unwrap_or(authority);
    let repo_path = repo_path.trim_matches('/').to_string();
    Some(RemoteRepo {
        web_url: format!("{scheme}://{host}/{repo_path}"),
        repo_path,
        branch: remote_branch,
    })
}

fn remote_host(app: &AppHandle, web_url: &str) -> RemoteHost {
    let host = host_from_base_url(web_url).to_ascii_lowercase();
    if host == "github.com" {
        return RemoteHost::GitHub;
    }
    if let Some((token, base)) = gitlab_oauth_info(app) {
        if host_from_base_url(&base).eq_ignore_ascii_case(&host) {
            return RemoteHost::GitLab {
                api_base: base.trim_end_matches('/').to_string(),
                token: Some(token),
            };
        }
    }
    if host == "gitlab.com" {
        return RemoteHost::GitLab {
            api_base: "https://gitlab.com".to_string(),
            token: None,
        };
    }
    RemoteHost::Other
}

fn api_client() -> Result<reqwest::Client, String> {
    crate::http::client()
}

const API_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(10);

async fn get_json(
    client: &reqwest::Client,
    url: &str,
    token: Option<&str>,
) -> Result<Option<serde_json::Value>, String> {
    let mut req = client
        .get(url)
        .timeout(API_TIMEOUT)
        .header("Accept", "application/vnd.github+json");
    if let Some(t) = token {
        req = req.header("Authorization", format!("Bearer {t}"));
    }
    let resp = req.send().await.map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Ok(None);
    }
    resp.json().await.map(Some).map_err(|e| e.to_string())
}

async fn post_json(
    client: &reqwest::Client,
    url: &str,
    token: &str,
    body: serde_json::Value,
    provider: &str,
) -> Result<serde_json::Value, String> {
    let resp = client
        .post(url)
        .timeout(API_TIMEOUT)
        .header("Accept", "application/vnd.github+json")
        .header("Authorization", format!("Bearer {token}"))
        .json(&body)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = resp.status();
    let text = resp.text().await.unwrap_or_default();
    if !status.is_success() {
        return Err(format!(
            "{provider} could not open the pull request ({status}). {}",
            text.trim()
        ));
    }
    serde_json::from_str(&text).map_err(|e| e.to_string())
}

fn compare_url(repo: &RemoteRepo, base: &str) -> String {
    format!(
        "{}/compare/{}...{}?expand=1",
        repo.web_url,
        encode_component(base),
        encode_component(&repo.branch)
    )
}

pub async fn git_branch_protection(app: AppHandle, path: String) -> Result<bool, String> {
    let Some(repo) = tokio::task::spawn_blocking(move || resolve_remote_repo(&path, None))
        .await
        .map_err(|e| e.to_string())?
    else {
        return Ok(false);
    };
    let client = api_client()?;
    match remote_host(&app, &repo.web_url) {
        RemoteHost::GitHub => {
            let token = github_oauth_token(&app);
            let base = format!("https://api.github.com/repos/{}", repo.repo_path);
            let branch = encode_component(&repo.branch).replace("%2F", "/");
            let protected = get_json(&client, &format!("{base}/branches/{branch}"), token.as_deref())
                .await?
                .and_then(|b| b["protected"].as_bool())
                .unwrap_or(false);
            if protected {
                return Ok(true);
            }
            let rules = get_json(&client, &format!("{base}/rules/branches/{branch}"), token.as_deref())
                .await?
                .and_then(|r| r.as_array().cloned())
                .unwrap_or_default();
            Ok(rules
                .iter()
                .any(|r| matches!(r["type"].as_str(), Some("pull_request" | "update"))))
        }
        RemoteHost::GitLab { api_base, token } => {
            let url = format!(
                "{}/api/v4/projects/{}/repository/branches/{}",
                api_base,
                encode_component(&repo.repo_path),
                encode_component(&repo.branch)
            );
            Ok(get_json(&client, &url, token.as_deref())
                .await?
                .and_then(|b| b["protected"].as_bool())
                .unwrap_or(false))
        }
        RemoteHost::Other => Ok(false),
    }
}

pub async fn git_open_pull_request(
    app: AppHandle,
    path: String,
    branch: String,
    base: String,
    title: String,
) -> Result<String, String> {
    let repo = tokio::task::spawn_blocking(move || resolve_remote_repo(&path, Some(&branch)))
        .await
        .map_err(|e| e.to_string())?
        .ok_or("No git remote is configured for this project")?;
    let client = api_client()?;
    match remote_host(&app, &repo.web_url) {
        RemoteHost::GitHub => {
            let Some(token) = github_oauth_token(&app) else {
                return Ok(compare_url(&repo, &base));
            };
            let json = post_json(
                &client,
                &format!("https://api.github.com/repos/{}/pulls", repo.repo_path),
                &token,
                serde_json::json!({ "title": title, "head": repo.branch, "base": base }),
                "GitHub",
            )
            .await?;
            json["html_url"]
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "GitHub response missing html_url".to_string())
        }
        RemoteHost::GitLab {
            api_base,
            token: Some(token),
        } => {
            let json = post_json(
                &client,
                &format!(
                    "{}/api/v4/projects/{}/merge_requests",
                    api_base,
                    encode_component(&repo.repo_path)
                ),
                &token,
                serde_json::json!({
                    "source_branch": repo.branch,
                    "target_branch": base,
                    "title": title,
                }),
                "GitLab",
            )
            .await?;
            json["web_url"]
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "GitLab response missing web_url".to_string())
        }
        RemoteHost::GitLab { token: None, .. } => Ok(format!(
            "{}/-/merge_requests/new?merge_request%5Bsource_branch%5D={}&merge_request%5Btarget_branch%5D={}",
            repo.web_url,
            encode_component(&repo.branch),
            encode_component(&base)
        )),
        RemoteHost::Other => Ok(compare_url(&repo, &base)),
    }
}
