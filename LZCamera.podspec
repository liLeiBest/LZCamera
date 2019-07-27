
Pod::Spec.new do |s|
  s.name             = 'LZCamera'
  s.version          = '0.4.0'
  s.summary          = '基于 AVFoundation 实现的摄像机功能'
  s.description      = <<-DESC
  基于 AVFoundation 实现的摄像机功能，共有三部分内容：
  1.核心功能实现部分。
  2.基于 Core 模块实现多媒体捕捉功能，包括：静态图片、短视频、长视频。
  3.基于 Core 模块实现机器码识别功能，机器码类型支持自定义。
                       DESC

  s.homepage         = 'https://github.com/liLeiBest'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lilei' => 'lilei0502@139.com' }
  s.source           = { :git => 'https://github.com/liLeiBest/LZCamera.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.frameworks          = 'AVFoundation','Foundation','UIKit','Photos','CoreServices','CoreMedia'
  s.source_files        = 'LZCamera/Classes/LZCamera.h'
  s.public_header_files = 'LZCamera/Classes/LZCamera.h'

  s.subspec 'Core' do |core|
	core.source_files        = 'LZCamera/Classes/Core/**/*.{h,m}'#, 'LZCamera/Classes/Core/*.storyboard'
    core.public_header_files = 'LZCamera/Classes/Core/**/*.h'
	core.resource            = 'LZCamera/Classes/core/Resources/LZCameraCore.bundle'
  end

  s.subspec 'MediaCapture' do |media|
	  media.source_files        = 'LZCamera/Classes/Media/**/*.{h,m}'#, 'LZCamera/Classes/Media/Controller/*.storyboard'
    media.public_header_files = 'LZCamera/Classes/Media/**/*.h'
    media.resource            = 'LZCamera/Classes/Media/Resources/LZCameraMedia.bundle'
    media.dependency 'LZCamera/Core'
	media.dependency 'LZCamera/Editor'
  end

  s.subspec 'CodeCapture' do |code|
     code.source_files        = 'LZCamera/Classes/Code/**/*.{h,m}'
     code.public_header_files = 'LZCamera/Classes/Code/**/*.h'
     code.resource            = 'LZCamera/Classes/Code/Resources/LZCameraCode.bundle'
     code.dependency 'LZCamera/Core'
  end

  s.subspec 'Editor' do |editor|
	  editor.source_files        = 'LZCamera/Classes/Editor/**/*.{h,m}'#, 'LZCamera/Classes/Editor/Controller/*.storyboard'
	  editor.public_header_files = 'LZCamera/Classes/Editor/**/*.h'
	  editor.resource            = 'LZCamera/Classes/Editor/Resources/LZCameraEditor.bundle'
  end
  
  pch_AF = <<-EOS
  #if DEBUG
  #define LZCameraLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
  #else
  #define LZCameraLog(fmt, ...)
  #endif
  #define LZCameraNSBundle(bundleName) bundleName.length ? [NSBundle bundleWithPath:[[NSBundle bundleForClass:NSClassFromString(@"LZCameraController")] pathForResource:bundleName ofType:@"bundle"]] :  [NSBundle bundleForClass:NSClassFromString(@"LZCameraController")]
  
  #import <AVFoundation/AVFoundation.h>
  #import <Photos/Photos.h>
  
  EOS
  s.prefix_header_contents = pch_AF;
  
end
