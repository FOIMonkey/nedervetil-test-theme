require File.expand_path(File.join(File.dirname(__FILE__), 'theme_spec_helper'))

# The invented help pack in lib/help_site/, served by core's help engine.
# spec/fixtures/files/help_pack.yml says what it should show.
RSpec.describe 'demo theme help pack', type: :request do
  include_context 'with incoming attention off'

  let(:expected) do
    YAML.safe_load_file(File.expand_path('fixtures/files/help_pack.yml', File.dirname(__FILE__)))
  end
  let(:page) { Nokogiri::HTML(response.body) }
  let(:content) { HelpSite.content }

  it 'is this theme’s pack' do
    expect(HelpSite.root).to eq(theme_root(ALAVETELI_TEST_THEME).join('lib/help_site').to_s)
  end

  it 'serves every page, with its title in the band' do
    expect(content.pages.map(&:path)).to eq(expected['pages'])
    expected['pages'].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
      expect(Nokogiri::HTML(response.body).css('.help-site h1.page-band__title').size).to eq(1), path
    end
  end

  describe 'the wording' do
    include_context 'with the theme wording'

    it 'gives the front page the demonstration’s title' do
      get '/help'
      expect(Nokogiri::HTML(response.body).at_css('h1.page-band__title').text).to eq('Help with the demonstration')
    end
  end

  it 'shows an article' do
    get expected['article']['path']
    expect(page.at_css('h1.page-band__title').text).to eq(expected['article']['title'])
    expect(page.at_css('.help-answer').text.squish).to include(expected['article']['text'])
  end

  # The help-find controller matches every typed word against each answer's
  # question, short answer and text, in the browser.
  def found(words)
    get '/help/search'
    response.parsed_body.select do |answer|
      text = answer.values_at('question', 'short', 'text').join(' ').downcase
      words.downcase.split.all? { text.include?(_1) }
    end
  end

  it 'gives search every answer, and finds one by its words' do
    get '/help'
    expect(page.at_css('[data-controller="help-find"]')['data-help-find-index-value']).to eq('/help/search')
    expect(found('').size).to eq(content.answers.size)
    expect(found(expected['search']['words']).map { _1['url'] }).to eq(expected['search']['finds'])
    expect(found(expected['search']['words_with_no_answer'])).to be_empty
  end

  it 'links an answer to its related answers' do
    get expected['related']['from']
    expect(page.css('.help-rows--next a').map { _1['href'] }).to eq(expected['related']['to'])
  end

  it 'explains a word where it is used, and on the words page' do
    glossary = expected['glossary']
    get glossary['page']
    word = page.css('.help-answer a.help-word').find { _1.text == glossary['shown_as'] }
    expect(word['href']).to eq(glossary['anchor'])
    expect(word['data-means']).to eq(glossary['means'])

    get '/help/words'
    entry = Nokogiri::HTML(response.body).at_css(".help-words dt##{glossary['anchor'].split('#').last}")
    expect(entry.text).to eq(glossary['title'])
    expect(entry.next_element.text).to eq(glossary['means'])
  end

  it 'checks a reply deadline on the answer that has core’s checker' do
    deadline = expected['deadline']
    get deadline['page']
    expect(page.at_css('details#help-deadline #help-date')).to be_present

    get deadline['page'], params: { received: deadline['received'] }
    due = Deadlines::Calendar.working_days_after(Date.iso8601(deadline['received']), AlaveteliConfiguration.reply_late_after_days, 'foi')
    result = Nokogiri::HTML(response.body).at_css('.help-date__result')
    expect(result.at_css('strong').text).to start_with(due.strftime('%A'))
    expect(result.text).to include('working days from then')
  end

  it 'explains every word an answer marks, and relates only answers that exist' do
    content.answers.each_value do |answer|
      expect(content.answers.keys).to include(*answer.related)
      answer.markdown.scan(HelpSite::Markdown::WORD) { |shown, word| expect(content.meaning(word || shown)).to be_present }
    end
  end

  it 'puts Help in the navigation, and leaves the older help pages alone' do
    get '/help'
    link = page.at_css('#navigation li.selected a')
    expect([link.text.strip, link['href']]).to eq(%w[Help /help])
    %w[/help/about /help/privacy /help/contact /help/requesting /help/officers /help/credits].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
      expect(response.body).not_to include('help-site'), path
    end
  end
end
