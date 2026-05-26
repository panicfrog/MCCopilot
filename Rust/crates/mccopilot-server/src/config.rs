use std::env;

#[derive(Debug, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub s3_endpoint: String,
    pub s3_bucket: String,
    pub s3_region: String,
    pub s3_access_key: String,
    pub s3_secret_key: String,
    pub jwt_secret: String,
}

impl ServerConfig {
    pub fn from_env() -> Self {
        Self {
            host: env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".into()),
            port: env::var("SERVER_PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(3000),
            s3_endpoint: env::var("S3_ENDPOINT")
                .unwrap_or_else(|_| "http://localhost:9000".into()),
            s3_bucket: env::var("S3_BUCKET").unwrap_or_else(|_| "mccopilot".into()),
            s3_region: env::var("S3_REGION").unwrap_or_else(|_| "us-east-1".into()),
            s3_access_key: env::var("S3_ACCESS_KEY")
                .unwrap_or_else(|_| "minioadmin".into()),
            s3_secret_key: env::var("S3_SECRET_KEY")
                .unwrap_or_else(|_| "minioadmin".into()),
            jwt_secret: env::var("JWT_SECRET")
                .unwrap_or_else(|_| "dev-secret-change-me".into()),
        }
    }
}
