def import_pods
    pod 'XLCUtils', :head
end

def import_pods_test
    pod 'OCMock', '~> 2.2.1'
end

target 'XJSBinding-ios' do
    platform :ios, '6.0'
    import_pods

    target 'XJSBindingTests-ios', :exclusive => true do
        import_pods_test
    end
end

target 'XJSBinding' do
    platform :osx, '10.8'
    import_pods

    target 'XJSBindingTests', :exclusive => true do
        import_pods_test
    end
end
