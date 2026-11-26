require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme help pages', type: :request do
  include_context 'with incoming attention off'

  let(:user) { FactoryBot.create(:user, name: 'Rowan Requester', trusted: true) }

  before do
    allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false)
    allow(AlaveteliFeatures.backend).to receive(:enabled?).and_call_original
    { alaveteli_pro: true }.each do |feature, enabled|
      allow(AlaveteliFeatures.backend).to receive(:enabled?).with(feature).and_return(enabled)
    end
  end

  def login = post('/profile/sign_in', params: { user_signin: { email: user.email, password: 'jonespassword' } })

  it 'describes reading by AI in the privacy notice, with the setting linked for a signed-in requester' do
    get '/help/privacy'
    expect(response.body).to include('id="ai"', 'demonstration')
    expect(response.body).not_to include('/profile/ai_reading')
    login
    get '/help/privacy'
    expect(Nokogiri::HTML(response.body).at_css('#ai_reading + dd a[href="/profile/ai_reading"]')).to be_present
  end

  # Core's page_band, with the band above the side column (the page styles
  # core keeps for its themes place it there).
  it 'opens each of the older help pages with the band every other page has' do
    %w[about alaveteli contact credits officers privacy pro requesting].each do |name|
      get "/help/#{name}"
      html = Nokogiri::HTML(response.body)
      expect(response).to have_http_status(:ok), name
      expect(html.at_css('body')['class'].split).to include('band-view'), name
      expect(html.css('header.page-band h1.page-band__title').size).to eq(1), name
      expect(html.css('h1').size).to eq(1), name
      expect(html.at_css("#help_#{name} > *")['class']).to eq('page-band'), name
    end
  end
end
