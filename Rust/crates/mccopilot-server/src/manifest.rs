use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::error::ServerError;
use crate::s3::S3Service;

const MANIFEST_KEY: &str = "manifest.json";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChunkMeta {
    pub hash: String,
    pub size: u64,
    pub path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlatformManifest {
    pub minimum_client_version: String,
    #[serde(default)]
    pub chunks: HashMap<String, ChunkMeta>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Manifest {
    pub version: String,
    pub rn: PlatformManifest,
}

impl Manifest {
    pub async fn from_s3(s3: &S3Service) -> Result<Self, ServerError> {
        match s3.get_object(MANIFEST_KEY).await {
            Ok(data) => {
                let manifest: Self = serde_json::from_slice(&data)
                    .map_err(|e| ServerError::Manifest(format!("Failed to parse manifest: {e}")))?;
                Ok(manifest)
            }
            Err(ServerError::NotFound(_)) => Ok(Self::default()),
            Err(e) => Err(e),
        }
    }

    pub async fn save_to_s3(&self, s3: &S3Service) -> Result<(), ServerError> {
        let data = serde_json::to_vec_pretty(self)
            .map_err(|e| ServerError::Manifest(format!("Failed to serialize manifest: {e}")))?;
        s3.put_object(MANIFEST_KEY, data, "application/json")
            .await
    }
}

impl Default for Manifest {
    fn default() -> Self {
        Self {
            version: "0.0.0".into(),
            rn: PlatformManifest {
                minimum_client_version: "1.0.0".into(),
                chunks: HashMap::new(),
            },
        }
    }
}
