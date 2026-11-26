require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

# The theme's own contact form shows core's person check (Turnstile) to a
# signed-out visitor, as HelpController asks.
RSpec.describe 'the contact form', type: :request do
  let(:user) { FactoryBot.create(:user, password: 'jonespassword') }

  before do
    allow(Turnstile).to receive_messages(configured?: true,
                                         site_key: 'site-key')
  end

  it 'shows the person check to a signed-out visitor' do
    get '/help/contact'
    expect(response.body).
      to include('cf-turnstile', 'site-key', 'data-action="contact"')
  end

  it 'does not show it to someone signed in' do
    post '/profile/sign_in',
         params: { user_signin: { email: user.email,
                                  password: 'jonespassword' } }
    get '/help/contact'
    expect(response.body).not_to include('cf-turnstile')
  end
end
