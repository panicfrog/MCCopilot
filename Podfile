ENV['RCT_NEW_ARCH_ENABLED'] = '1'

# Resolve react_native_pods.rb with node to allow for hoisting
require Pod::Executable.execute_command('node', ['-p',
  'require.resolve(
    "react-native/scripts/react_native_pods.rb",
    {paths: [process.argv[1]]},
  )', File.join(__dir__, 'ReactNative')]).strip

platform :ios, '16.0'
prepare_react_native_project!

# Flutter configuration
flutter_application_path = 'Flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

rn_dir = 'ReactNative'
rn_modules = "#{rn_dir}/node_modules"

target 'MCCopilot' do
  use_react_native!(
    :path => "#{rn_modules}/react-native",
    :hermes_enabled => true,
    :fabric_enabled => true,
    :app_path => "#{Pod::Config.instance.installation_root}/#{rn_dir}"
  )
  
  # Re.Pack native module
  pod 'callstack-repack', :path => "#{rn_modules}/@callstack/repack"

  # Rust MccopilotBridge via CocoaPods
  pod 'MccopilotBridge', :path => 'Rust/crates/mccopilot/product/apple'

  # NitroModules core
  ENV['NODE_PATH'] = File.join(__dir__, rn_modules)
  pod 'NitroModules', :path => "#{rn_modules}/react-native-nitro-modules"

  # NitroModule: MccopilotRN (C++ -> Rust FFI bridge for React Native)
  pod 'MccopilotRN', :path => "#{rn_dir}/packages/react-native-mccopilot"

  # Flutter integration via CocoaPods
  install_all_flutter_pods(flutter_application_path)
  
  post_install do |installer|
    # Flutter post install
    flutter_post_install(installer) if defined?(flutter_post_install)
    
    # React Native post install
    react_native_post_install(
      installer,
      "#{rn_modules}/react-native",
      :mac_catalyst_enabled => false
    )
    
    # Common configurations
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end
end

