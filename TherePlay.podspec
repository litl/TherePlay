Pod::Spec.new do |s|
  s.name         = "TherePlay"
  s.platform     = :ios
  s.summary      = "iOS library for AirPlay"
  s.license      = 'MIT'
  s.author       = { "litl, LLC" => "cbridges@litl.com" }
  s.source       = { :git => "https://github.com/litl/TherePlay.git" }
  s.source_files = "TherePlay/*.{h,m}"
end
