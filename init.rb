require 'redmine'
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib/"
require 'restrict_time_entry_patch'
require 'restrict_setting_patch'
Redmine::Plugin.register :redmine_timelog_restrict_date do
  name 'Redmine Timelog Restrict Date plugin'
  author 'Target Integration'
  author_url 'https://www.targetintegration.com'
  description 'Redmine Timelog Restrict Date plugin was created by the team at Target Integration www.targetintegration.com.'
  version '0.0.1'
  settings default: {}, partial: 'settings/timelog_restrict_settings.html.erb'
end
