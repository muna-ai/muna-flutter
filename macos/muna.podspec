Pod::Spec.new do |s|
  s.name             = 'muna'
  s.version          = '0.0.1'
  s.summary          = 'Run AI models in Flutter.'
  s.homepage         = 'https://muna.ai'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'NatML Inc.' => 'hi@muna.ai' }
  s.source           = { :path => '.' }
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '10.15'
  s.vendored_libraries = 'Function.dylib'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
