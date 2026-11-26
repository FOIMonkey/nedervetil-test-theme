require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme wording' do
  include_context 'with the theme wording'

  describe 'dates' do
    include DateTimeHelper

    it 'are in British order' do
      expect(simple_date(Date.new(2026, 3, 3), format: :text)).
        to eq('3 March 2026')
    end
  end

  describe 'the page-not-found page', type: :request do
    before { allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false) }

    it 'doesn’t say requests are published after a delay, or offer a second search box' do
      get '/no-such-page-anywhere'
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('will be delayed')
      expect(Nokogiri::HTML(response.body).css('#error-page form')).to be_empty
    end

    # In the theme's words: core's title begins with "Sorry".
    it 'has its title in the band every other page has' do
      get '/no-such-page-anywhere'
      html = Nokogiri::HTML(response.body)
      expect(html.at_css('body')['class'].split).to include('band-view')
      expect(html.css('header.page-band h1.page-band__title').map(&:text)).
        to eq(['Page not found'])
      expect(html.css('h1').size).to eq(1)
    end
  end
end
