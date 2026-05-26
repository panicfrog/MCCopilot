use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
};

use crate::error::ServerError;

pub async fn auth_required(request: Request, next: Next) -> Result<Response, ServerError> {
    let token = request
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "));

    match token {
        Some(_) => Ok(next.run(request).await),
        None => Err(ServerError::Unauthorized),
    }
}
