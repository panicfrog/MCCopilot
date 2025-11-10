# Resolve react_native_pods.rb with node to allow for hoisting
require Pod::Executable.execute_command('node', ['-p',
  'require.resolve(
    "react-native/scripts/react_native_pods.rb",
    {paths: [process.argv[1]]},
  )', File.join(__dir__, 'ReactNative')]).strip

platform :ios, '15.1'
prepare_react_native_project!

# Flutter configuration
flutter_application_path = 'Flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'MCCopilot' do
  # React Native configuration - following official docs
  # Don't use use_frameworks! for React Native integration
  use_react_native!(
    :path => "./ReactNative/node_modules/react-native",
    :hermes_enabled => true,
    :fabric_enabled => false,
    :app_path => "#{Pod::Config.instance.installation_root}/ReactNative"
  )

  # Flutter integration via CocoaPods
  install_all_flutter_pods(flutter_application_path)
  
  post_install do |installer|
    # Flutter post install
    flutter_post_install(installer) if defined?(flutter_post_install)
    
    # React Native post install
    react_native_post_install(
      installer,
      "./ReactNative/node_modules/react-native",
      :mac_catalyst_enabled => false
    )
    
    # Common configurations
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.1'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end
end

