use std::net::SocketAddr;

use axum::{response::IntoResponse, routing::get, Json, Router};
use serde::Serialize;

#[derive(Serialize)]
struct Todo {
    id: usize,
    task: String,
    done: bool,
}

impl Todo {
    fn new(id: usize, task: &'static str) -> Self {
        Self {
            id,
            task: String::from(task),
            done: false,
        }
    }
}

async fn todos() -> impl IntoResponse {
    let todos: Vec<Todo> = vec![Todo::new(
        1,
        "convert all my GitHub Actions pipelines to Nix",
    )];

    Json(todos)
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    axum::Server::bind(&addr)
        .serve(app().into_make_service())
        .await
        .unwrap();
}

fn app() -> Router {
    Router::new().route("/todos", get(todos))
}

#[cfg(test)]
mod tests {
    use std::net::TcpListener;

    use hyper::{Body, Request};

    use super::*;

    // Not an awesome test but it gets the job done for demo purposes
    #[tokio::test]
    async fn todos_endpoint() {
        let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
        let listener = TcpListener::bind(addr).unwrap();

        tokio::spawn(async move {
            axum::Server::from_tcp(listener)
                .unwrap()
                .serve(app().into_make_service())
                .await
                .unwrap();
        });

        let client = hyper::Client::new();

        let response = client
            .request(
                Request::builder()
                    .method(hyper::Method::GET)
                    .uri(format!("http://{}/todos", addr))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();

        let code = response.status();

        assert_eq!(code, hyper::StatusCode::OK);
    }
}
