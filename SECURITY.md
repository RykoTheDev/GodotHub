# Security Policy

## Supported Versions

Security fixes are applied to the latest release line only. Please update to the
newest release before reporting a problem.

| Version | Supported          |
| ------- | ------------------ |
| 1.5.x   | :white_check_mark: |
| < 1.5   | :x:                |

## Reporting a Vulnerability

Please report security issues privately so a fix can ship before the problem is
public. Do not open a public GitHub issue for a security vulnerability.

Use one of these channels:

- **GitHub Security Advisories (preferred).** Open a private report at
  https://github.com/RykoTheDev/godothub/security/advisories/new
- **Email.** `theryko11@gmail.com`

Please include as much of the following as you can:

- A description of the issue and the impact you believe it has.
- The affected version or commit, and your operating system.
- Steps to reproduce, a proof of concept, or a relevant crash or log.
- Any suggested fix or mitigation, if you have one.

### What to expect

- **Acknowledgement.** We aim to reply within a few days.
- **Assessment.** We confirm the issue and agree on its severity.
- **Fix and disclosure.** We prepare a fix, cut a release, and credit you in the
  release notes unless you ask to stay anonymous.

Please allow a reasonable window for a fix to ship before disclosing the issue
publicly.

## Scope

GodotHub is a desktop application built on Tauri. A report is in scope when it
affects:

- The application itself: the Rust backend, the web frontend, or the Tauri IPC
  boundary between them.
- The auto-updater or the release artifacts, for example a signature or
  integrity problem.
- Handling of untrusted input such as downloaded archives, Git repositories, or
  project files on disk.

Out of scope: vulnerabilities in Godot itself, in third-party services the app
talks to, and issues that require an already-compromised machine.
