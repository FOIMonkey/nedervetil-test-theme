require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme pages', type: :request do
  before { allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false) }
  include_context 'with the theme wording'

  let(:page) { Nokogiri::HTML(response.body) }

  describe 'the home page' do
    before do
      allow(AlaveteliConfiguration).
        to receive(:authority_must_respond).and_return(true)
      get '/'
    end

    it 'asks what you want to know, and searches the documents' do
      expect(page.at_css('h1').text).to eq('What do you want to know?')
      expect(page.at_css('.torch__search')['action']).to eq('/documents')
      expect(page.css('.torch__row a').size).to eq(Topics::Topic::HOME + 1)
      expect(response.body).not_to include('Your right to know')
      expect(response.body).not_to include('around the world')
    end

    it 'shows one search box: its own, not the masthead one too' do
      expect(page.at_css('body')['class']).to include('has-page-search')
    end

    it 'sends the masthead search straight to the documents' do
      form = page.at_css('#navigation_search_form')
      expect(form['action']).to eq('/documents')
      expect(form.at_css('input[type="search"]')['name']).to eq('q')
    end

    it 'has one h1 and uses h2 for its sections' do
      expect(page.css('h1').size).to eq(1)
      expect(page.css('#content h2').map { _1.text.strip }).
        to include('Questions people ask')
      expect(page.css('#content h3, #content h4')).to be_empty
    end

    it 'lists no requests: they are private' do
      expect(response.body).not_to include('Latest requests')
    end
  end

  describe 'the request list' do
    before { get '/list' }

    it 'labels each date field' do
      expect(response).to redirect_to('/documents')
      follow_redirect!
      expect(page.at_css('label[for="documents-q"]')).to be_present
    end
  end

  describe 'the authority list, showing one letter' do
    before { get '/body/list/w' }

    it 'keeps the chosen letter in the row, marked as current' do
      current = page.at_css('.alphabet__letter--current')

      expect(current.text).to eq('W')
      expect(current['aria-current']).to eq('true')
      expect(page.css('a.alphabet__letter').size).to eq(25)
    end
  end

  describe 'the request page' do
    let(:info_request) { FactoryBot.create(:info_request) }

    it 'runs on core\'s controllers, loaded with a nonce' do
      post '/profile/sign_in', params: { user_signin: { email: info_request.user.email, password: 'jonespassword' } }
      get "/request/#{info_request.url_title}"
      script = page.at_css('script[type="importmap"]')

      expect(script).to be_present
      expect(script['nonce']).to be_present
      expect(page.at_css('body')['data-controller']).
        to eq('confirm method-link form-lock')
      expect(page.css('script[src*="/assets/features"]')).to be_empty
    end
  end

  describe 'other pages' do
    it 'load core\'s controllers too, and no jQuery bundle' do
      get '/help/about'
      expect(page.at_css('script[type="importmap"]')).to be_present
      expect(page.css('script[src*="/assets/application"]')).to be_empty
    end
  end

  describe 'a signed-in account' do
    # Not the home page: from core #93 it sends a signed-in account on to the
    # inbox.
    it 'marks the page as signed in' do
      sign_in(FactoryBot.create(:user))
      get '/help/about'

      expect(page.at_css('body')['class']).to include('is-signed-in')
    end
  end

  describe 'help pages' do
    %w[about privacy officers contact credits alaveteli].each do |name|
      it "has a #{name} page with one h1 and no invitation to make a request" do
        get "/help/#{name}"

        expect(response.status).to eq(200)
        expect(page.css('h1').size).to eq(1)
        expect(response.body).not_to include('We are a <strong>charity')
        expect(page.css('#content a[href="/new"], #content a[href="/select_authority"]')).
          to be_empty
      end
    end

    it 'keeps the requester\'s guides out of the list for visitors' do
      get '/help/about'
      expect(page.css('#right_column_flip a').map { _1.text }).
        not_to include('Making requests')
    end
  end

  describe 'a person\'s own page' do
    let(:user) { FactoryBot.create(:user) }
    let!(:private_request) do
      # new requests are created requester_only
      FactoryBot.create(:info_request, user: user, title: 'A private matter')
    end

    it 'keeps their requests in the inbox, not on the account page' do
      post '/profile/sign_in', params: {
        user_signin: { email: user.email, password: 'jonespassword' }
      }
      get "/user/#{user.url_name}"

      expect(private_request.reload.prominence).to eq('requester_only')
      expect(response.body).not_to include('A private matter')

      get "/user/#{user.url_name}/requests"
      expect(response).to redirect_to('/pro/info_requests')
    end

    it 'gives them an Account page of settings, with no list waiting for a status and no wall' do
      pro = FactoryBot.create(:user)
      post '/profile/sign_in', params: { user_signin: { email: pro.email, password: 'jonespassword' } }
      get "/user/#{pro.url_name}/profile"
      expect(page.at_css('h1').text).to eq('Account')
      expect(page.css('.account-settings .account-settings__name').map(&:text)).
        to include('Name', 'Email', 'Password', 'Automatic reading of replies')
      expect(page.css('.account-settings a').map { _1['href'] }).to include('/profile/ai_reading')
      expect(page.at_css('.undescribed_requests, #undescribed_requests')).to be_nil
      expect(response.body).not_to include('Reading replies with AI', 'My wall')
      expect(page.css('.logged-in-menu__links a').map(&:text)).to include('Account')
    end

    it 'does not list them to a visitor' do
      get "/user/#{user.url_name}"

      expect(page.css('#private_foi_requests')).to be_empty
      expect(response.body).not_to include('A private matter')
    end
  end

  describe 'sign-in' do
    before do
      allow(AlaveteliConfiguration).
        to receive(:read_only_features).and_return(['signups'])
      get '/profile/sign_in'
    end

    it 'has one h1, which says to sign in' do
      expect(page.css('h1').size).to eq(1)
      expect(page.at_css('h1').text).to match(/sign in/i)
    end
  end
end
