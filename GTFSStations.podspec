#
# Be sure to run `pod lib lint SBCategories.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "GTFSStations"
  s.version          = "0.0.1"
  s.summary          = "GTFS Stations takes GTFS data and organizes it into stations"
  s.description      = <<-DESC
                       Take a look at StationManager. This will allow you to get stations and predictions within a given time of your the date you pass in.
                       DESC
  s.homepage         = "https://github.com/schrockblock/gtfs-stations"
  s.license          = 'MIT'
  s.author           = { "Elliot" => "ephherd@gmail.com" }
  s.source           = { :git => "https://github.com/schrockblock/gtfs-stations.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/schrockblock'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
