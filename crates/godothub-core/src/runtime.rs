use std::future::Future;
use std::sync::OnceLock;

use tokio::runtime::{Handle, Runtime};
use tokio::task::JoinHandle;

static HANDLE: OnceLock<Handle> = OnceLock::new();
static OWNED: OnceLock<Runtime> = OnceLock::new();

pub fn set(handle: Handle) {
    let _ = HANDLE.set(handle);
}

pub fn handle() -> Handle {
    if let Some(handle) = HANDLE.get() {
        return handle.clone();
    }
    OWNED
        .get_or_init(|| Runtime::new().expect("failed to start the async runtime"))
        .handle()
        .clone()
}

pub fn spawn<F>(future: F) -> JoinHandle<F::Output>
where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
{
    handle().spawn(future)
}

pub fn spawn_blocking<F, R>(task: F) -> JoinHandle<R>
where
    F: FnOnce() -> R + Send + 'static,
    R: Send + 'static,
{
    handle().spawn_blocking(task)
}
