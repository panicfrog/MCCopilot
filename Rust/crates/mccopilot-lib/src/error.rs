//! 统一错误处理

use thiserror::Error;

/// MCCopilot 核心错误类型
#[derive(Debug, Error)]
pub enum MCCopilotError {
    /// 加密相关错误
    #[error("Crypto error: {0}")]
    Crypto(String),

    /// 网络相关错误
    #[error("Network error: {0}")]
    Network(String),

    /// 插件相关错误
    #[error("Plugin error: {0}")]
    Plugin(String),

    /// 参数校验错误
    #[error("Invalid argument: {0}")]
    InvalidArgument(String),

    /// IO 错误
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// 序列化错误
    #[error("Serialization error: {0}")]
    Serialization(String),

    /// 其他错误
    #[error("{0}")]
    Other(String),
}

/// 统一结果类型
pub type Result<T> = std::result::Result<T, MCCopilotError>;

impl From<base64::DecodeError> for MCCopilotError {
    fn from(err: base64::DecodeError) -> Self {
        MCCopilotError::Crypto(format!("Base64 decode error: {}", err))
    }
}

impl From<serde_json::Error> for MCCopilotError {
    fn from(err: serde_json::Error) -> Self {
        MCCopilotError::Serialization(err.to_string())
    }
}

impl From<hex::FromHexError> for MCCopilotError {
    fn from(err: hex::FromHexError) -> Self {
        MCCopilotError::Crypto(format!("Hex decode error: {}", err))
    }
}
