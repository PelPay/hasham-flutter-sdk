Pod::Spec.new do |s|
  s.name             = 'hasham_mobile_sdk'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin for the Chamsswitch Hasham Mobile SDK'
  s.description      = <<~DESC
    Hardware-backed device attestation (Play Integrity / App Attest) and
    PCI DSS-compliant PIN management for Flutter applications.
  DESC

  s.homepage         = 'https://github.com/PelPay/iam'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Chamsswitch Ltd. All rights reserved.' }
  s.author           = { 'Chamsswitch Platform Team' => 'platform@chamsswitch.com' }
  s.source           = { :git => 'https://github.com/PelPay/iam.git', :tag => "sdk/flutter/v#{s.version}" }

  s.ios.deployment_target = '16.0'
  s.swift_versions        = ['5.9']

  # Flutter plugin bridge + embedded SDK sources (self-contained)
  s.source_files = [
    "Classes/**/*.swift",
    "#{__dir__}/../../../ios/Sources/HashamMobileSDK/**/*.swift",
  ]

  s.dependency 'Flutter'
  s.frameworks = 'Security', 'DeviceCheck'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
