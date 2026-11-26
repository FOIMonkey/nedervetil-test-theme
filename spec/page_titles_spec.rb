require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

# One title style for the whole site: a page's title is in core's page band,
# and a browser draws it the same on every page.
RSpec.describe 'demo theme page titles', type: :system, js: true do
  def title_as_drawn(path)
    visit path
    expect(page).to have_css('.page-band h1')
    page.evaluate_script(<<~JS)
      (() => {
        const title = document.querySelector('.page-band h1')
        const band = title.closest('.page-band')
        const style = getComputedStyle(title)
        return {
          size: style.fontSize, weight: style.fontWeight, line: style.lineHeight, colour: style.color,
          left: Math.round(title.getBoundingClientRect().left),
          band: getComputedStyle(band).backgroundColor,
          bandTop: Math.round(band.getBoundingClientRect().top)
        }
      })()
    JS
  end

  # The older help pages have a side column. Core's page styles put the band
  # above both columns; without that it lands in a cell under them.
  it 'draws an older help page\'s title as on any other page, above its side column' do
    elsewhere = title_as_drawn('/topics')
    %w[/help/about /help/privacy].each do |path|
      expect(title_as_drawn(path)).to eq(elsewhere), path
    end
  end
end
