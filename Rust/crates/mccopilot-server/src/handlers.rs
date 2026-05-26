use axum::{
    extract::{Multipart, Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;

use crate::error::ServerError;
use crate::manifest::Manifest;
use crate::s3::S3Service;

const MANIFEST_CACHE_TTL: Duration = Duration::from_secs(60);

#[derive(Debug, Clone)]
pub struct ManifestCache {
    pub manifest: Manifest,
    pub fetched_at: Instant,
}

#[derive(Clone)]
pub struct AppState {
    pub s3: Arc<S3Service>,
    pub manifest_cache: Arc<RwLock<Option<ManifestCache>>>,
}

impl AppState {
    pub fn new(s3: S3Service) -> Self {
        Self {
            s3: Arc::new(s3),
            manifest_cache: Arc::new(RwLock::new(None)),
        }
    }

    pub async fn get_manifest(&self) -> Result<Manifest, ServerError> {
        {
            let cache = self.manifest_cache.read().await;
            if let Some(cached) = cache.as_ref()
                && cached.fetched_at.elapsed() < MANIFEST_CACHE_TTL
            {
                return Ok(cached.manifest.clone());
            }
        }

        let manifest = Manifest::from_s3(&self.s3).await?;

        {
            let mut cache = self.manifest_cache.write().await;
            *cache = Some(ManifestCache {
                manifest: manifest.clone(),
                fetched_at: Instant::now(),
            });
        }

        Ok(manifest)
    }

    pub async fn invalidate_manifest_cache(&self) {
        let mut cache = self.manifest_cache.write().await;
        *cache = None;
    }
}

// GET /api/v1/manifest
pub async fn get_manifest(
    State(state): State<AppState>,
) -> Result<Json<Manifest>, ServerError> {
    let manifest = state.get_manifest().await?;
    Ok(Json(manifest))
}

// GET /api/v1/chunks/:id
pub async fn get_chunk(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> Result<Response, ServerError> {
    let manifest = state.get_manifest().await?;

    let chunk_meta = manifest
        .rn
        .chunks
        .get(&id)
        .ok_or_else(|| ServerError::NotFound(format!("Chunk not found: {id}")))?;

    let data = state.s3.get_object(&chunk_meta.path).await?;

    let etag = format!("\"{}\"", chunk_meta.hash);

    Ok((
        StatusCode::OK,
        [
            ("content-type", "application/javascript"),
            ("cache-control", "public, max-age=31536000, immutable"),
            ("etag", etag.as_str()),
        ],
        data,
    )
        .into_response())
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UploadResponse {
    pub chunk_id: String,
    pub hash: String,
    pub size: u64,
    pub path: String,
}

// POST /api/v1/upload
pub async fn upload_chunk(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> Result<Json<UploadResponse>, ServerError> {
    let mut chunk_id: Option<String> = None;
    let mut chunk_data: Option<Vec<u8>> = None;
    let mut platform: String = "rn".to_string();

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| ServerError::BadRequest(format!("Multipart error: {e}")))?
    {
        let name = field.name().unwrap_or("").to_string();

        match name.as_str() {
            "chunk_id" => {
                let text = field
                    .text()
                    .await
                    .map_err(|e| ServerError::BadRequest(format!("Read chunk_id: {e}")))?;
                chunk_id = Some(text);
            }
            "platform" => {
                let text = field
                    .text()
                    .await
                    .map_err(|e| ServerError::BadRequest(format!("Read platform: {e}")))?;
                platform = text;
            }
            "file" => {
                let bytes = field
                    .bytes()
                    .await
                    .map_err(|e| ServerError::BadRequest(format!("Read file: {e}")))?;
                chunk_data = Some(bytes.to_vec());
            }
            _ => {}
        }
    }

    let chunk_id = chunk_id.ok_or_else(|| ServerError::BadRequest("Missing chunk_id".into()))?;
    let chunk_data =
        chunk_data.ok_or_else(|| ServerError::BadRequest("Missing file".into()))?;

    let mut hasher = Sha256::new();
    hasher.update(&chunk_data);
    let hash = hex::encode(hasher.finalize());

    let s3_key = format!("{platform}/chunks/{chunk_id}.{hash}.js");
    let size = chunk_data.len() as u64;

    state
        .s3
        .put_object(&s3_key, chunk_data, "application/javascript")
        .await?;

    state.invalidate_manifest_cache().await;

    Ok(Json(UploadResponse {
        chunk_id,
        hash,
        size,
        path: s3_key,
    }))
}

// PUT /api/v1/manifest
pub async fn update_manifest(
    State(state): State<AppState>,
    Json(manifest): Json<Manifest>,
) -> Result<Json<Manifest>, ServerError> {
    manifest.save_to_s3(&state.s3).await?;

    state.invalidate_manifest_cache().await;

    Ok(Json(manifest))
}
