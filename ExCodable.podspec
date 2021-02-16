Pod::Spec.new do |s|
    
    # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.name          = "ExCodable"
    s.version       = "0.1.0"
    s.summary       = "Extensions for Swift Codable"
    # s.description   = "Extensions for Swift."
    s.homepage      = "https://github.com/iwill/ExCodable"
    
    # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.license       = "MIT"
    s.author        = { "Mr. Ming" => "i+ExCodable@iwill.im" }
    s.social_media_url = "https://iwill.im/about/"
    
    # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.deployment_target = "10.0"
    s.osx.deployment_target = "11.0"
    # s.tvos.deployment_target = "10.0"
    # s.watchos.deployment_target = "2.0"
    s.swift_version = "5.0"
    
    # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source        = { :git => "https://github.com/iwill/ExCodable.git", :tag => s.version.to_s }
    
    # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source_files  = "Sources", "Sources/**/*.{swift}"
    # s.exclude_files = "Sources/Exclude"
    # s.public_header_files = "Sources/**/*.h"
    
    # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    # s.resource      = "icon.png"
    # s.resources     = "Resources/*.png"
    # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
    
    # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.framework     = "Foundation"
    # s.frameworks    = "Foundation", "UIKit", "WebKit", "CoreGraphics"
    # s.library       = "iconv"
    # s.libraries     = "iconv", "xml2"
    
    # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    # s.xcconfig      = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
    # s.dependency "JSONKit", "~> 1.4"
    
end
