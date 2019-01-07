#
# Be sure to run `pod lib lint SwiftyRedux.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyRedux'
  s.version          = '0.1.0'
  s.summary          = 'Swifty implementation of Redux'
  s.swift_version    = '4.2'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Swifty implementation of Redux with optional add-ons.
                       DESC

  s.homepage         = 'https://github.com/a-voronov/swifty-redux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alexander Voronov' => 'voronovaleksandr91@gmail.com' }
  s.source           = { :git => 'git@github.com:a-voronov/swifty-redux.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/aleks_voronov'

  s.ios.deployment_target = '10.0'

  s.default_subspecs = 'Core', 'BatchedActions', 'SideEffects'

  s.subspec 'Core' do |ss|
    ss.source_files = 'SwiftyRedux/Sources/Core/**/*.{swift}'

    ss.test_spec 'Tests' do |ts|
      ts.source_files = 'SwiftyRedux/Tests/Core/**/*.{swift}'
    end
  end

  s.subspec 'BatchedActions' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.source_files = 'SwiftyRedux/Sources/BatchedActions/**/*.{swift}'
  end

  s.subspec 'Epics' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.dependency 'ReactiveSwift', '~> 4.0'
    ss.source_files = 'SwiftyRedux/Sources/Epics/**/*.{swift}'
  end

  s.subspec 'SideEffects' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.source_files = 'SwiftyRedux/Sources/SideEffects/**/*.{swift}'
  end

  s.subspec 'All' do |ss|
    ss.dependency 'SwiftyRedux/Core'
    ss.dependency 'SwiftyRedux/BatchedActions'
    ss.dependency 'SwiftyRedux/Epics'
    ss.dependency 'SwiftyRedux/SideEffects'
  end
end
