require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

# The theme's images, fonts and Sass come before core's of the same name.
RSpec.describe 'Theme assets' do
  let(:assets) { Rails.application.assets }
  let(:theme_assets) { theme_root(ALAVETELI_TEST_THEME).join('app/assets') }
  let(:core_images) { Rails.root.join('app/assets/images') }

  it "serves the theme's images in place of core's" do
    images = theme_assets.join('images')
    replaced = Dir.glob('**/*', base: images).select do
      images.join(_1).file? && core_images.join(_1).file?
    end
    expect(replaced).not_to be_empty

    replaced.each do |name|
      asset = assets.load_path.find(name)
      expect(asset.path).to eq(images.join(name)), name
      expect(ActionController::Base.helpers.asset_path(name)).
        to eq("/assets/#{asset.digested_path}")
    end
  end

  it "builds the site's stylesheet with the theme's partials and fonts" do
    font = assets.load_path.find('roboto-latin-wght-normal.woff2')
    expect(font.path).
      to eq(theme_assets.join('fonts/roboto-latin-wght-normal.woff2'))

    css = assets.load_path.find('responsive/application.css').compiled_content
    expect(css).to include(%(url("/assets/#{font.digested_path}")))
  end

  it 'builds its own admin stylesheet' do
    css = assets.load_path.find('admin-skin.css').compiled_content
    expect(css).to include('#admin-bar')
  end
end
