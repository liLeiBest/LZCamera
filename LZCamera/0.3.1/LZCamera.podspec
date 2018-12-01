
Pod::Spec.new do |s|
  s.name             = 'LZCamera'
  s.version          = '0.3.1'
  s.summary          = '基于 AVFoundation 实现的摄像机功能'
  s.description      = <<-DESC
  基于 AVFoundation 实现的摄像机功能，共有三部分内容：
  1.核心功能实现部分。
  2.基于 Core 模块实现多媒体捕捉功能，包括：静态图片、短视频、长视频。
  3.基于 Core 模块实现机器码识别功能，机器码类型支持自定义。
                       DESC

  s.homepage         = 'https://github.com/liLeiBest/LZCamera'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lilei' => 'lilei0502@139.com' }
  s.source           = { :git => 'git@github.com:liLeiBest/LZCamera.git', :tag => s.version.to_s }

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
     code.resource            = 'LZCamera/Classes/Code/Resources/LZCameraCode.bundle'
     code.dependency 'LZCamera/Core'
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
