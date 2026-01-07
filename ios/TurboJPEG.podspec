Pod::Spec.new do |s|
  s.name             = 'TurboJPEG'
  s.version          = '2.1.5'
  s.summary          = 'libjpeg-turbo is a JPEG image codec that uses SIMD instructions to accelerate baseline JPEG compression and decompression'
  s.description      = <<-DESC
libjpeg-turbo is a JPEG image codec that uses SIMD instructions (MMX, SSE2, NEON, AltiVec) to accelerate baseline JPEG compression and decompression on x86, x86-64, ARM, and PowerPC systems.
                       DESC
  s.homepage         = 'https://libjpeg-turbo.org/'
  s.license          = { :type => 'IJG' }
  s.author           = { 'libjpeg-turbo' => 'https://libjpeg-turbo.org/' }
  s.platform         = :ios, '13.0'
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'TurboJPEG.xcframework'
  s.source           = { :path => '.' }
  s.preserve_paths   = 'TurboJPEG.xcframework'
end

