Pod::Spec.new do |s|
  s.name         = 'MccopilotBridge'
  s.version      = '0.1.0'
  s.summary      = 'Rust-backed cryptographic bridge for MCCopilot'
  s.homepage     = 'https://github.com/example/MCCopilot'
  s.license      = { :type => 'MIT' }
  s.author       = 'MCCopilot'
  s.source       = { :git => '', :tag => s.version.to_s }
  s.ios.deployment_target = '16.0'
  s.swift_version = '5.9'

  s.source_files = 'Sources/**/*.swift'
  s.vendored_frameworks = 'MccopilotBridge.xcframework'
end
