source 'https://github.com/CocoaPods/Specs.git'

def import_pods
    pod 'XLCUtils'
end

def import_pods_test
    pod 'OCMock', '~> 2.2.1', :inhibit_warnings => true
end

target 'XJSBinding-ios' do
    platform :ios, '7.0'
    import_pods

    target 'XJSBindingTests-ios' do
        import_pods_test
    end

    target 'XJSBindingApp' do
        import_pods_test
    end
end

target 'XJSBinding' do
    platform :osx, '10.9'
    import_pods

    target 'XJSBindingTests' do
        import_pods_test
    end
end
