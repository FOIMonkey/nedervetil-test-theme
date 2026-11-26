theme_name = File.split(File.expand_path("../..", __FILE__))[1]
theme_name.gsub!('-', '_')
THEME_NAME = theme_name

class ActionController::Base
  path_function_name = "set_view_paths_for_#{THEME_NAME}"
  before_action path_function_name.to_sym
  send :define_method, path_function_name do
    self.prepend_view_path File.join(File.dirname(__FILE__), "views")
  end
end

Rails.application.config.to_prepare do
  # The app's privacy gate renders pages, so the theme's views come first.
  ApplicationController.prepend_before_action :"set_view_paths_for_#{THEME_NAME}"
end

theme_assets =
  Pathname.new(File.dirname(__FILE__)).join('../app/assets').cleanpath

# Sass looks in the theme's stylesheets before core's, so the theme's partials
# replace core's of the same name. The admin's stylesheet is the theme's own;
# its script is core's admin importmap.
Rails.application.config.dartsass.build_options.unshift(
  "--load-path=#{theme_assets.join('stylesheets')}"
)
Rails.application.config.dartsass.builds[
  theme_assets.join('stylesheets/admin-skin.scss').to_s
] = 'admin-skin.css'

# The theme's images, fonts and scripts win over core's of the same name.
# Propshaft puts the app's own folders first as it starts, so this waits
# until it has.
Rails.application.config.to_prepare do
  paths = Rails.application.config.assets.paths
  %w[fonts images javascripts].each do |type|
    path = theme_assets.join(type).to_s
    paths.unshift(path) unless paths.include?(path)
  end
end

# The theme's wording first, then Alaveteli's. The inbox's wording
# (locale_alaveteli_pro) is for every account.
paths = []
paths << File.join(File.dirname(__FILE__), '..', 'locale-theme')
paths << 'locale_alaveteli_pro'
paths << 'locale'
repos = paths.map do |path|
  FastGettext::TranslationRepository.build('app', :path => path, :type => :po)
end
AlaveteliLocalization.set_default_text_domain('app', repos)

require File.expand_path('../model_patches.rb', __FILE__)
