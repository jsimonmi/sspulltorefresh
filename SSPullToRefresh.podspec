Pod::Spec.new do |s|
  s.name      = 'SSPullToRefresh'
  s.version   = '1.2.1'
  s.summary   = 'Simple and highly customizable pull to refresh view.'
  s.homepage  = 'https://github.com/jsimonmi/sspulltorefresh'
  s.author    = { 'Sam Soffes' => 'sam@samsoff.es' }
  s.source    = { :git => 'https://github.com/jsimonmi/sspulltorefresh.git', :commit => '20c077253d1d3b08f5eddc517cc5cf951df8ea63' }
  s.license   = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.source_files = '*.{h,m}'
  s.description = 'SSPullToRefresh is a simple andhighly customizable pull to refresh view. It lets you implement a content view separate so you don\'t have to hack up the pulling logic everything you want to customize the appearance.'
  s.platform = :ios
  s.requires_arc = true
end
