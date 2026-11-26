require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme refusal sections' do
  it "are the UK Acts' exemptions" do
    expect(Legislation.find('foi').refusals.map(&:to_s)).
      to include('Section 12', 'Section 14', 'Section 21', 'Section 44')
    expect(Legislation.find('eir').refusals.map(&:to_s)).
      to eq(['Regulation 12', 'Regulation 13'])
  end
end
