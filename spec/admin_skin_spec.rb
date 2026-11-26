require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme admin skin', type: :request do
  include ActiveJob::TestHelper
  include DisclosuresHelpers
  include_context 'with document OCR off'

  let(:owner) { FactoryBot.create(:user, name: 'Rowan Requester') }
  let(:admin) { FactoryBot.create(:admin_user) }
  let(:body) { FactoryBot.create(:public_body, name: 'Synthetic County Council') }
  let(:info_request) { FactoryBot.create(:info_request, user: owner, public_body: body, title: 'Gritting routes 2024') }

  def page = Nokogiri::HTML(response.body)

  def make_document
    delivered_document(info_request, 'runs.txt', 'text/plain', "Gritting by ward\nNorth: 12 runs\n",
                       by: owner, ready: false)
  end

  describe 'the admin bar' do
    it 'uses the theme’s admin stylesheet and a viewport on admin pages, and the bar’s on public ones' do
      sign_in(admin)
      get '/admin'
      expect(page.at_css('meta[name="viewport"]')).to be_present
      expect(page.css('link[rel="stylesheet"]').map { _1['href'] }).to include(a_string_matching(/admin-skin/))
      expect(response.body).not_to include('alaveteli.org/community', 'Knowledge Hub')
      get '/help/about'
      expect(page.css('link[rel="stylesheet"]').map { _1['href'] }).to include(a_string_matching(/admin-skin/))
      sign_in(owner)
      get '/help/about'
      expect(page.css('link[rel="stylesheet"]').map { _1['href'] }).not_to include(a_string_matching(/admin-skin/))
    end

    # Core's template is blank, so an override left at an old path fails silently.
    it 'puts the question mark in the bar, ahead of the site name' do
      sign_in(admin)
      get '/admin'
      marks = page.css('#admin-bar a.admin-bar__brand img')
      expect(marks.size).to eq(1)
      expect(marks.first['src']).to match(%r{/question-mark(-\h{8})?\.svg})
      expect(marks.first['alt']).to eq('')
    end
  end

  describe 'without Bootstrap' do
    let(:theme_file) { ->(path) { theme_root(ALAVETELI_TEST_THEME).join(path).read } }

    def assets = page.css('script[src], link[rel="stylesheet"]').map { _1['src'] || _1['href'] }

    def core_admin_or_bootstrap = %r{bootstrap|/assets/admin(-\h+)?\.(js|css)}

    it 'loads the theme’s admin stylesheet, core’s admin importmap and nothing of Bootstrap, on admin and public pages' do
      sign_in(admin)
      get '/admin'
      expect(assets).to include(a_string_matching(%r{/assets/admin-skin(-\h+)?\.css}))
      expect(page.at_css('script[type="importmap"]')).to be_present
      expect(assets.grep(/\.js/).grep(/admin-skin|jquery/)).to eq([])
      expect(assets.grep(core_admin_or_bootstrap)).to eq([])
      get '/help/about'
      expect(assets).to include(a_string_matching(/admin-skin/))
      expect(assets.grep(core_admin_or_bootstrap)).to eq([])

      %w[layouts/admin general/_admin_stylesheet].each do |view|
        expect(theme_file.("lib/views/#{view}.html.erb")).not_to match(/(stylesheet_link|javascript_include)_tag[^%]*(bootstrap|["']admin["'])/)
      end
    end

    it 'brings no script of its own: the admin runs on core’s controllers' do
      expect(theme_root(ALAVETELI_TEST_THEME).glob('app/assets/javascripts/*admin*')).to eq([])
    end

    it 'serves admin assets with no Bootstrap code in them' do
      sign_in(admin)
      get '/admin'
      assets.grep(/admin-skin/).each do |asset|
        get asset
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to match(/bootstrap|twipsy|glyphicons|\.popover|\.tooltip\(|\.tab\(/i)
      end
    end

    it 'gives every toggle in core’s markup a target it can find by id' do
      make_document
      sign_in(admin)
      %W[/admin/requests/#{info_request.id} /admin/users/#{owner.id} /admin/bodies/#{body.id}/edit].each do |path|
        get path
        toggles = page.css('[data-toggle]')
        expect(toggles.map { _1['data-toggle'] }.uniq - %w[collapse dropdown tab]).to eq([])
        toggles.reject { _1['data-toggle'] == 'dropdown' }.each do |toggle|
          id = (toggle['data-target'] || toggle['href']).delete_prefix('#')
          expect(page.css("[id='#{id}']").size).to eq(1), "#{path}: #{id}"
        end
      end
    end
  end
end
