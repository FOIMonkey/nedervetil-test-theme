require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

RSpec.describe 'demo theme data' do
  data = File.expand_path('../data', __dir__)

  it 'maps the Commissioner’s names to the sample data’s sic: tags' do
    rows = CSV.read(File.join(data, 'foi_statistics', 'scotland-crosswalk.csv'),
                    headers: true)
    expect(rows.headers).to eq(%w[sic_name tag our_name note])
    tags = SampleData::Dataset::AUTHORITIES.values.
           flat_map { |_, _, tag_string| tag_string.scan(/\bsic:(\S+)/).flatten }
    expect(rows.map { |row| row['tag'] }.uniq - tags).to be_empty
  end
end
