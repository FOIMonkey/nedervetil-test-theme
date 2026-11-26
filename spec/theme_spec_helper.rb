# File.dirname(__FILE__), not __dir__: the theme is reached through a symlink
# in lib/themes, and __dir__ would follow it out of the Alaveteli checkout.
unless defined?(ALAVETELI_TEST_THEME)
  ALAVETELI_TEST_THEME = ENV.fetch(
    'ALAVETELI_TEST_THEME',
    File.basename(File.expand_path('..', File.dirname(__FILE__)))
  )
end
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec', 'spec_helper'))

THEME_LOCALE_PATH = theme_root(ALAVETELI_TEST_THEME).join('locale-theme').to_s

# Core's spec_helper points the translations at its own fixtures, which drops
# the theme's wording. Specs that check wording include this context to put it
# back, and to restore core's afterwards.
RSpec.shared_context 'with the theme wording' do
  def use_locale_paths(*paths)
    repos = paths.map do |path|
      FastGettext::TranslationRepository.build('app', path: path, type: :po)
    end
    AlaveteliLocalization.set_default_text_domain('app', repos)
    FastGettext.reload!
    Thread.current[:fast_gettext_cache] = nil
    FastGettext.cache.switch_to(FastGettext.text_domain, FastGettext.locale)
  end

  before(:all) do
    use_locale_paths(THEME_LOCALE_PATH, Rails.root.join('locale').to_s)
  end

  after(:all) do
    use_locale_paths(Rails.root.join('spec', 'fixtures', 'locale').to_s)
  end
end
