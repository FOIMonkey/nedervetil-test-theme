require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

# What leads a visitor to make a request is hidden while core has sign-ups
# closed (READ_ONLY_FEATURES), and shown once they are open. The stylesheet
# does the hiding (responsive/features/visitor), so this needs a browser.
RSpec.describe 'demo theme and core\'s sign-up switch', type: :system, js: true do
  # "Can't find the one you want?" under the list of authorities.
  let(:missing_authority) { '#content a[href$="#missing_body"]' }

  it 'shows a visitor the way to ask for a missing authority while sign-ups are open' do
    visit '/body/list/all'
    expect(page).to have_css('body.is-visitor:not(.signups-closed)')
    expect(page).to have_css(missing_authority)
  end

  it 'hides it from a visitor while sign-ups are closed' do
    allow(AlaveteliConfiguration).
      to receive(:read_only_features).and_return(['signups'])
    visit '/body/list/all'
    expect(page).to have_css('body.is-visitor.signups-closed')
    # still in the page, and not shown
    expect(page).to have_css(missing_authority, visible: :hidden)
    expect(page).to have_no_css(missing_authority)
  end
end
