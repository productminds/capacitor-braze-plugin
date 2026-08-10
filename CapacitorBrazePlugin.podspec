require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorBrazePlugin'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  # Braze iOS SDK (BrazeKit). To upgrade, bump the version below and check
  # https://github.com/braze-inc/braze-swift-sdk/releases for breaking changes.
  s.dependency 'BrazeKit', '~> 18.0'
  s.swift_version = '5.1'
end
