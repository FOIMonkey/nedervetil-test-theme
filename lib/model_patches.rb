# The UK Acts' exemptions. Core has no refusal sections unless a theme sets
# them; refusal advice and the sections an AI outcome reading records as cited
# are found with this list.
Rails.configuration.to_prepare do
  Legislation.refusals = {
    foi: ['s 12', 's 14', *(21..44).map { |n| "s #{n}" }],
    eir: ['reg 12', 'reg 13']
  }
end
