Pod::Spec.new do |s|
  s.name             = 'SwiftyRedux'
  s.version          = '0.3.0'
  s.summary          = 'Swifty implementation of Redux'
  s.swift_version    = '5.0'

  s.description      = <<-DESC
Swifty implementation of Redux with optional add-ons.
                       DESC

  s.homepage         = 'https://github.com/a-voronov/swifty-redux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Oleksandr Voronov' => 'voronovaleksandr91@gmail.com' }
  s.source           = { :git => 'https://github.com/a-voronov/swifty-redux.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/aleks_voronov'

  s.ios.deployment_target = '10.0'

  s.default_subspecs = 'Core', 'Steroids', 'Command', 'BatchedActions', 'SideEffects'

  s.subspec 'Core' do |ss|
    ss.source_files = 'SwiftyRedux/Sources/Core/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/Core/**/*.{swift}'
    end
  end

  s.subspec 'All' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.dependency 'SwiftyRedux/Steroids'
    ss.dependency 'SwiftyRedux/Command'
    ss.dependency 'SwiftyRedux/BatchedActions'
    ss.dependency 'SwiftyRedux/SideEffects'
    ss.dependency 'SwiftyRedux/Epics'
    ss.dependency 'SwiftyRedux/ReactiveExtensions'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/**/*.{swift}'
    end
  end

  s.subspec 'Steroids' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.source_files = 'SwiftyRedux/Sources/Steroids/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/Steroids/**/*.{swift}'
    end
  end

  s.subspec 'BatchedActions' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.source_files = 'SwiftyRedux/Sources/BatchedActions/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/BatchedActions/**/*.{swift}'
    end
  end

  s.subspec 'Command' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.source_files = 'SwiftyRedux/Sources/Command/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/Command/**/*.{swift}'
    end
  end

  s.subspec 'SideEffects' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.source_files = 'SwiftyRedux/Sources/SideEffects/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/SideEffects/**/*.{swift}'
    end
  end

  s.subspec 'Epics' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.dependency 'ReactiveSwift', '~> 6.0'
    ss.source_files = 'SwiftyRedux/Sources/Epics/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/Epics/**/*.{swift}'
    end
  end

  s.subspec 'ReactiveExtensions' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.dependency 'SwiftyRedux/Steroids'
    ss.dependency 'ReactiveSwift', '~> 6.0'
    ss.source_files = 'SwiftyRedux/Sources/ReactiveExtensions/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/ReactiveExtensions/**/*.{swift}'
    end
  end
end
