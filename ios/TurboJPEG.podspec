Pod::Spec.new do |s|
  s.name             = 'TurboJPEG'
  s.version          = '2.1.5'
  s.summary          = 'libjpeg-turbo is a JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression'
  s.description      = <<-DESC
libjpeg-turbo is a JPEG image codec that uses SIMD instructions (MMX, SSE2, NEON, AltiVec) to accelerate baseline JPEG compression and decompression on x86, x86-64, ARM, and PowerPC systems.

This pod provides pre-built iOS xcframework binaries for libjpeg-turbo 2.1.5, supporting:
- iOS arm64 (device)
- iOS arm64 + x86_64 (simulator)
                       DESC
  s.homepage         = 'https://libjpeg-turbo.org/'
  s.license          = { :type => 'IJG', :text => 'Independent JPEG Group License' }
  s.author           = { 'libjpeg-turbo' => 'https://libjpeg-turbo.org/' }
  s.platform         = :ios, '13.0'
  s.ios.deployment_target = '13.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'TurboJPEG.xcframework'
  s.preserve_paths   = 'TurboJPEG.xcframework'
  s.public_header_files = 'TurboJPEG.xcframework/**/Headers/*.h'
end

