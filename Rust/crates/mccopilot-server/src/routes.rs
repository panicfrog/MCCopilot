use axum::{
    middleware,
    routing::{get, post, put},
    Router,
};

use crate::handlers::{self, AppState};
use crate::middleware::auth_required;

pub fn create_router(state: AppState) -> Router {
    let public_routes = Router::new()
        .route("/api/v1/manifest", get(handlers::get_manifest))
        .route("/api/v1/chunks/{id}", get(handlers::get_chunk));

    let protected_routes = Router::new()
        .route("/api/v1/upload", post(handlers::upload_chunk))
        .route("/api/v1/manifest", put(handlers::update_manifest))
        .layer(middleware::from_fn(auth_required));

    Router::new()
        .merge(public_routes)
        .merge(protected_routes)
        .with_state(state)
}
