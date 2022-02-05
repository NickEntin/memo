Pod::Spec.new do |s|
  s.name             = 'Memo'
  s.version          = '0.1.0'
  s.summary          = 'Inter-device communication framework'

  s.homepage         = 'https://github.com/NickEntin/Memo'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'Nick Entin' => 'nick@entin.io' }
  s.source           = { :git => 'https://github.com/NickEntin/Memo.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '11.0'
  s.swift_versions = '5.0'

  s.source_files = 'Memo/Classes/**/*'
end
