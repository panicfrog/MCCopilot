require_relative 'nitrogen/generated/ios/NitroMccopilot+autolinking'

Pod::Spec.new do |s|
  s.name         = 'MccopilotRN'
  s.version      = '0.1.0'
  s.summary      = 'NitroModule C++ bridge for MccopilotBridge'
  s.homepage     = 'https://github.com/example/MCCopilot'
  s.license      = { :type => 'MIT' }
  s.author       = 'MCCopilot'
  s.source       = { :git => '', :tag => s.version.to_s }
  s.ios.deployment_target = '16.0'

  s.source_files = 'cpp/**/*.{hpp,cpp,h}'
  s.dependency 'MccopilotBridge'

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/cpp"'
  }

  add_nitrogen_files(s)
end
