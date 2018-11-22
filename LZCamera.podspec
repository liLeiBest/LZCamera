
Pod::Spec.new do |s|
  s.name             = 'LZCamera'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LZCamera.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/liLeiBest/LZCamera'
  # s.screenshots    = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lilei_hapy@163.com' => 'lilei_hapy@163.com' }
  s.source           = { :git => 'git@github.com:liLeiBest/LZCamera.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.frameworks          = 'AVFoundation','Foundation','UIKit'
  s.source_files        = 'LZCamera/Classes/LZCamera.h'
  s.public_header_files = 'LZCamera/Classes/LZCamera.h'

  s.subspec 'Core' do |core|
    core.source_files        = 'LZCamera/Classes/Core/**/*'
    core.public_header_files = 'LZCamera/Classes/Core/**/*.h'
  end

  s.subspec 'Capture' do |capture|
    capture.source_files        = 'LZCamera/Classes/Capture/**/*.{h,m}'
    capture.public_header_files = 'LZCamera/Classes/Capture/**/*.h'
    capture.resource            = 'LZCamera/Classes/Capture/Resources/LZCameraCapture.bundle'
    capture.dependency 'LZCamera/Core'
  end

  s.subspec 'Code' do |code|
     code.source_files        = 'LZCamera/Classes/Code/**/*'
     code.public_header_files = 'LZCamera/Classes/Code/**/*.h'
  end

  pch_AF = <<-EOS
  #if DEBUG
  #define LZCameraLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
  #else
  #define LZCameraLogfmt, ...)
  #endif
  EOS
  s.prefix_header_contents = pch_AF;
  
end
