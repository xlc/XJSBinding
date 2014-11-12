Pod::Spec.new do |s|
    s.name         = 'XJSBinding'
    s.version      = '0.1.3'
    s.summary      = 'Javascript binding for Objective-C. Powered by Spidermonkey JS engine.'
    s.homepage     = 'https://github.com/xlc/XJSBinding'
    s.license      = 'MIT'
    s.author       = { 'Xiliang Chen' => 'xlchen1291@gmail.com' }
    s.source       = { :git => 'https://github.com/xlc/XJSBinding.git', :tag => "#{s.version}" }
    s.source_files = 'XJSBinding/**/*.{h,hh,m,mm}', 'Spidermonkey/**/*.h'
    s.private_header_files = '*Private.h', '*.hh'
    s.preserve_paths = 'Spidermonkey/**/*'
    s.header_mappings_dir = 'Spidermonkey/include'

    s.requires_arc = true

    s.dependency 'XLCUtils'
    s.libraries = 'z'
    s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC -ljs_static',
                   'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/XJSBinding/Spidermonkey/include" "${PODS_ROOT}/Headers"',
                   'LIBRARY_SEARCH_PATHS' => '"${PODS_ROOT}/XJSBinding/Spidermonkey/${CONFIGURATION}"' }

    s.ios.deployment_target = '6.0'
    s.osx.deployment_target = '10.8'

end

