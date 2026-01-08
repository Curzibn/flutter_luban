Pod::Spec.new do |s|
  s.name             = 'luban'
  s.version          = '2.0.1'
  s.summary          = 'Luban 2 — An efficient and concise Flutter image compression library that pixel-perfectly replicates the compression strategy of WeChat Moments.'
  s.description      = <<-DESC
Luban Flutter is an efficient and concise Flutter image compression plugin that uses TurboJPEG for high-performance image compression. It provides a simple API and compression effects close to WeChat Moments.

Features:
- High performance: Based on TurboJPEG native library, fast compression speed
- Intelligent compression: Adaptive compression algorithm that dynamically adjusts strategy based on image characteristics
- Cross-platform: Supports Android and iOS
- Easy to use: Simple API design, supports single and batch compression
- Robust: Comprehensive error handling and edge case handling
                       DESC
  s.homepage         = 'https://github.com/Curzibn/flutter_luban'
  s.license          = { :type => 'Apache', :file => '../LICENSE' }
  s.author           = { 'Curzibn' => 'https://github.com/Curzibn' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.dependency       'TurboJPEG', '~> 2.1.5'
  s.platform         = :ios, '13.0'
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.resource_bundles = {
    'luban_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end
