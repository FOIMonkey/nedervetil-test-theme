require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme page shell', type: :request do
  let(:page) { Nokogiri::HTML(response.body) }
  let(:nav_links) { page.css('#topnav .navigation a').map { _1.text.strip } }
  let(:footer_links) { page.css('#footer a').map { _1.text.strip } }

  context 'for a visitor' do
    before { get '/help/about' }

    it 'marks the body so the stylesheet can hide things from visitors' do
      expect(page.at_css('body')['class'].split).to include('is-visitor')
    end

    it 'does not mark the body as sign-ups closed while core has them open' do
      expect(page.at_css('body')['class'].split).not_to include('signups-closed')
    end

    it 'has reader navigation only' do
      expect(nav_links).to eq(%w[Topics Documents Authorities Help])
    end

    it 'marks Topics current on the topics pages' do
      ['/topics', '/topics/streets'].each do |path|
        get path
        expect(page.css('#topnav .navigation li.selected a').map(&:text)).to eq(['Topics']), path
      end
    end

    it 'draws the help pack’s signs beside a topic page’s two groups' do
      get '/topics/streets'
      expect(page.css('.topic-group-head svg.help-sign.topic-sign').size).to eq(2)
      expect(page.css('.topic-group-head h2').map(&:text)).to eq(['Look it up', 'Ask for it'])
    end

    it 'offers sign in, and no sign up, in the masthead and not in the footer' do
      link = page.at_css('#banner a.banner-signin')
      expect(link.text).to eq('Sign in')
      expect(link['href']).to start_with('/profile/sign_in')
      expect(page.at_css('#banner').text).not_to match(/sign up/i)
      expect(page.css('#banner #logged_in_bar')).to be_empty
      expect(page.css('#footer a[href^="/profile/sign_in"]')).to be_empty
    end

    it 'has one h1, and it is not the site name' do
      expect(page.css('h1').size).to eq(1)
      expect(page.css('#banner h1')).to be_empty
    end

    it 'shows the site name without a strapline' do
      expect(page.at_css('#banner .site-title__logo')).to be_present
      expect(page.css('#banner .site-strapline')).to be_empty
    end

    it 'shows the question mark in the home link, named by the site name' do
      link = page.at_css('#banner a#logo.site-title__logo')
      expect(link['href']).to eq('/')
      expect(link.at_css('.site-title__name').text.strip).to eq(AlaveteliConfiguration.site_name)

      marks = link.css('img.site-title__mark')
      expect(marks.size).to eq(1)
      expect(marks.first['src']).to match(%r{/question-mark(-\h{8})?\.svg})
      expect(marks.first['alt']).to eq('')
      expect([marks.first['width'], marks.first['height']]).to eq(%w[48 48])
    end

    it 'uses the question mark as the favicon, from the theme’s own assets' do
      icons = page.css('link[rel="icon"]')
      svg = icons.find { _1['type'] == 'image/svg+xml' }
      ico = icons.find { _1['href'].include?('favicon') }
      expect(svg['href']).to match(%r{\A/assets/question-mark(-\h{8})?\.svg\z})
      expect(ico['href']).to match(%r{\A/assets/favicon(-\h{8})?\.ico\z})
      expect(icons.map { _1['href'] }).to all(start_with('/assets/'))

      theme_ico = File.binread(File.join(File.dirname(__FILE__), '..', 'app', 'assets', 'images', 'favicon.ico'))
      get ico['href']
      expect(response.body.b).to eq(theme_ico)
    end

    it 'has no menu button' do
      expect(page.css('.rsp_menu_button')).to be_empty
    end

    it 'has a dark look for a reader whose device asks for one' do
      expect(page.at_css('meta[name="color-scheme"]')['content']).
        to eq('light dark')

      stylesheet = page.css('link[rel="stylesheet"]').map { _1['href'] }.
        find { _1 =~ %r{/responsive/application-\h+\.css} }
      get stylesheet

      # built the way production builds it; the dark page colour is there,
      # and only for screens
      expect(response.body).
        to match(/@media screen and \(prefers-color-scheme:\s*dark\)\s*\{\s*:root\s*\{[^}]*--color-page:\s*var\(--night\)/)
    end

    it 'loads fonts from this site only' do
      expect(response.body).not_to include('fonts.googleapis.com')
      expect(page.at_css('link[rel="preload"][as="font"]')['href']).
        to start_with('/assets/roboto-latin-wght-normal')
    end
  end

  # Core's READ_ONLY_FEATURES decides; the theme only passes it on.
  context 'for a visitor while core has sign-ups closed' do
    before do
      allow(AlaveteliConfiguration).
        to receive(:read_only_features).and_return(['signups'])
      get '/help/about'
    end

    it 'marks the body so the stylesheet can hide what leads to a request' do
      expect(page.at_css('body')['class'].split).
        to include('is-visitor', 'signups-closed')
    end
  end

  # As the site runs: Pro on, so core gives the account the inbox. From
  # nedervetil #93 every signed-in account has it, flag or not; the theme
  # asks core (request_journey_pro?), so this holds on either core.
  context 'for the signed-in owner', feature: :alaveteli_pro do
    let(:user) { FactoryBot.create(:user) }

    before do
      post '/profile/sign_in', params: {
        user_signin: { email: user.email, password: 'jonespassword' }
      }
      get '/help/about'
    end

    it 'marks the body as signed in' do
      expect(page.at_css('body')['class']).to include('is-signed-in')
    end

    it 'shows the inbox navigation' do
      expect(nav_links).to eq(['Home', 'Make request', 'Topics', 'Documents', 'Authorities', 'Help'])
    end

    it 'shows the account menu, with no "pro" pill, and no sign-in link' do
      expect(page.css('#banner #logged_in_bar .account-link')).to be_present
      expect(page.css('#logged_in_bar .pro-pill')).to be_empty
      expect(page.css('#banner a.banner-signin')).to be_empty
    end
  end

  context 'for a signed-in owner' do
    it 'shows their name in the account menu, with no profile photo' do
      user = FactoryBot.create(:user)
      post '/profile/sign_in', params: { user_signin: { email: user.email, password: 'jonespassword' } }
      get '/help/about'
      expect(page.at_css('#logged_in_bar .profile-summary__name').text).to include(user.name)
      expect(page.css('#logged_in_bar img')).to be_empty
    end
  end

  context 'on a page with a second navigation row' do
    before { get '/documents' }

    it 'provides document search instead of public request categories' do
      expect(page.at_css('#documents-q')).to be_present
      expect(page.css('#subnav a')).to be_empty
    end

    it 'marks the row up as a list inside a labelled nav' do
      expect(page.at_css('#topnav nav[aria-label]')).to be_present
      expect(page.css('#subnav ul[role]')).to be_empty
      expect(page.css('[id="navigation"]').size).to eq(1)
    end
  end
end
