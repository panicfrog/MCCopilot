use aws_config::Region;
use aws_sdk_s3::config::BehaviorVersion;
use aws_sdk_s3::Client as S3Client;

use crate::config::ServerConfig;
use crate::error::ServerError;

#[derive(Debug, Clone)]
pub struct S3Service {
    client: S3Client,
    bucket: String,
}

impl S3Service {
    pub async fn new(config: &ServerConfig) -> Self {
        let credentials = aws_sdk_s3::config::Credentials::new(
            &config.s3_access_key,
            &config.s3_secret_key,
            None,
            None,
            "rustfs",
        );

        let s3_config = aws_sdk_s3::Config::builder()
            .behavior_version(BehaviorVersion::latest())
            .region(Region::new(config.s3_region.clone()))
            .endpoint_url(&config.s3_endpoint)
            .force_path_style(true)
            .credentials_provider(credentials)
            .build();

        Self {
            client: S3Client::from_conf(s3_config),
            bucket: config.s3_bucket.clone(),
        }
    }

    pub async fn get_object(&self, key: &str) -> Result<Vec<u8>, ServerError> {
        let output = self
            .client
            .get_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
            .map_err(|e| {
                let msg = e.to_string();
                let debug_msg = format!("{e:?}");
                if msg.contains("NoSuchKey")
                    || msg.contains("404")
                    || debug_msg.contains("NoSuchKey")
                {
                    ServerError::NotFound(format!("Object not found: {key}"))
                } else {
                    ServerError::S3(msg)
                }
            })?;

        let body = output
            .body
            .collect()
            .await
            .map_err(|e| ServerError::S3(format!("Failed to read body: {e}")))?;

        Ok(body.to_vec())
    }

    pub async fn put_object(
        &self,
        key: &str,
        data: Vec<u8>,
        content_type: &str,
    ) -> Result<(), ServerError> {
        self.client
            .put_object()
            .bucket(&self.bucket)
            .key(key)
            .body(data.into())
            .content_type(content_type)
            .send()
            .await?;

        Ok(())
    }

    pub async fn delete_object(&self, key: &str) -> Result<(), ServerError> {
        self.client
            .delete_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await?;

        Ok(())
    }

    pub async fn ensure_bucket(&self) -> Result<(), ServerError> {
        let exists = self
            .client
            .head_bucket()
            .bucket(&self.bucket)
            .send()
            .await
            .is_ok();

        if !exists {
            self.client
                .create_bucket()
                .bucket(&self.bucket)
                .send()
                .await?;
        }

        Ok(())
    }
}
