use std::panic::{catch_unwind, resume_unwind, AssertUnwindSafe};
use std::sync::mpsc::{channel, Sender};
use std::sync::OnceLock;

type Job = Box<dyn FnOnce() + Send>;

fn sender() -> &'static Sender<Job> {
    static SENDER: OnceLock<Sender<Job>> = OnceLock::new();
    SENDER.get_or_init(|| {
        let (tx, rx) = channel::<Job>();
        std::thread::Builder::new()
            .name("godothub-commands".into())
            .spawn(move || {
                for job in rx {
                    job();
                }
            })
            .expect("failed to start the command thread");
        tx
    })
}

pub async fn serial<F, R>(task: F) -> R
where
    F: FnOnce() -> R + Send + 'static,
    R: Send + 'static,
{
    let (tx, rx) = tokio::sync::oneshot::channel();
    let job: Job = Box::new(move || {
        let _ = tx.send(catch_unwind(AssertUnwindSafe(task)));
    });
    sender().send(job).expect("command thread stopped");
    match rx.await.expect("command thread dropped a task") {
        Ok(value) => value,
        Err(panic) => resume_unwind(panic),
    }
}

#[cfg(test)]
mod tests {
    use super::serial;

    #[test]
    fn runs_tasks_in_submission_order_off_the_calling_thread() {
        let caller = std::thread::current().id();
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let order = std::sync::Arc::new(std::sync::Mutex::new(Vec::new()));
        runtime.block_on(async {
            let mut pending = Vec::new();
            for i in 0..20 {
                let order = order.clone();
                pending.push(serial(move || {
                    order.lock().unwrap().push(i);
                    std::thread::current().id()
                }));
            }
            for task in pending {
                assert_ne!(task.await, caller);
            }
        });
        assert_eq!(*order.lock().unwrap(), (0..20).collect::<Vec<_>>());
    }
}
