use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde_json::json;

#[derive(Debug, thiserror::Error)]
pub enum ServerError {
    #[error("S3 error: {0}")]
    S3(String),

    #[error("Manifest error: {0}")]
    Manifest(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Unauthorized")]
    Unauthorized,

    #[error("Bad request: {0}")]
    BadRequest(String),

    #[error("Internal error: {0}")]
    Internal(String),
}

impl IntoResponse for ServerError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            ServerError::S3(msg) => (StatusCode::BAD_GATEWAY, msg.clone()),
            ServerError::Manifest(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg.clone()),
            ServerError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            ServerError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".into()),
            ServerError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            ServerError::Internal(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg.clone()),
        };

        let body = axum::Json(json!({
            "error": message,
            "status": status.as_u16(),
        }));

        (status, body).into_response()
    }
}

// Generic conversion for any S3 SDK error → ServerError::S3
impl<E: std::fmt::Display> From<aws_sdk_s3::error::SdkError<E>> for ServerError {
    fn from(err: aws_sdk_s3::error::SdkError<E>) -> Self {
        ServerError::S3(err.to_string())
    }
}
