use tracing_subscriber::EnvFilter;

use mccopilot_server::config::ServerConfig;
use mccopilot_server::handlers::AppState;
use mccopilot_server::routes;
use mccopilot_server::s3::S3Service;

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();

    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let config = ServerConfig::from_env();
    let addr = format!("{}:{}", config.host, config.port);

    let s3 = S3Service::new(&config).await;
    if let Err(e) = s3.ensure_bucket().await {
        tracing::warn!("Bucket ensure failed (may already exist): {e}");
    } else {
        tracing::info!("Bucket '{}' ready", config.s3_bucket);
    }

    let state = AppState::new(s3);
    let app = routes::create_router(state);

    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("Failed to bind address");

    tracing::info!("mccopilot-server listening on {}", addr);

    axum::serve(listener, app)
        .await
        .expect("Server error");
}
