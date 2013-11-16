Pod::Spec.new do |s|
    s.name         = 'XJSBinding'
    s.version      = '0.0.1'
    s.summary      = 'Javascript binding for Objective-C. Powered by Spidermonkey JS engine.'
    s.homepage     = 'https://github.com/xlc/XJSBinding'
    s.license      = 'MIT'
    s.author       = { 'Xiliang Chen' => 'xlchen1291@gmail.com' }
    s.source       = { :git => 'https://github.com/xlc/XJSBinding.git', :commit => '8e29b60ee5171082126bd0c554059bff345ad7c8' }
    s.source_files = 'XJSBinding/**/*.{h,hh,m,mm}'
    s.private_header_files = '*Private.h', '*.hh'
    s.preserve_paths = 'Spidermonkey/**/*'
    s.header_mappings_dir = 'Spidermonkey/include'

    s.requires_arc = true

    s.dependency 'XLCUtils'
    s.libraries = 'z'
    s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC -ljs_static', 'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/XJSBinding/Spidermonkey/include"' }

    s.ios.deployment_target = '6.0'
    s.osx.deployment_target = '10.8'

    #s.subspec 'Debug' do |sp|
    #    sp.xcconfig = { 'LIBRARY_SEARCH_PATHS' => '"${PODS_ROOT}/XJSBinding/Spidermonkey/debug"'}
    #end

    #s.subspec 'Release' do |sp|
    #    sp.xcconfig = { 'LIBRARY_SEARCH_PATHS' => '"${PODS_ROOT}/XJSBinding/Spidermonkey/release"' }
    #end

end

