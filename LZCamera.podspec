
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
  s.author           = { 'lilei' => 'lilei0502@139.com' }
  s.source           = { :git => 'git@github.com:liLeiBest/LZCamera.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.frameworks          = 'AVFoundation','Foundation','UIKit'
  s.source_files        = 'LZCamera/Classes/LZCamera.h'
  s.public_header_files = 'LZCamera/Classes/LZCamera.h'

  s.subspec 'Core' do |core|
    core.source_files        = 'LZCamera/Classes/Core/**/*.{h,m}'
    core.public_header_files = 'LZCamera/Classes/Core/**/*.h'
  end

  s.subspec 'MediaCapture' do |media|
    media.source_files        = 'LZCamera/Classes/Media/**/*.{h,m}'
    media.public_header_files = 'LZCamera/Classes/Media/**/*.h'
    media.resource            = 'LZCamera/Classes/Media/Resources/LZCameraMedia.bundle'
    media.dependency 'LZCamera/Core'
  end

  s.subspec 'CodeCapture' do |code|
     code.source_files        = 'LZCamera/Classes/Code/**/*.{h,m}'
     code.public_header_files = 'LZCamera/Classes/Code/**/*.h'
  end

  pch_AF = <<-EOS
  #if DEBUG
  #define LZCameraLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
  #else
  #define LZCameraLog(fmt, ...)
  #endif
  #define LZCameraNSBundle(bundleName) [NSBundle bundleWithPath:[[NSBundle bundleForClass:NSClassFromString(@"LZCameraController")] pathForResource:bundleName ofType:@"bundle"]]
  EOS
  s.prefix_header_contents = pch_AF;
  
end
