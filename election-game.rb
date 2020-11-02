#!/usr/bin/env ruby

require "erb"
require "roo"
require "yaml"

directory       = File.expand_path(File.dirname(__FILE__))
candidates      = YAML.load_file(File.join(directory, "candidates.yml"))
candidate_names = candidates.keys
districts       = YAML.load_file(File.join(directory, "districts.yml"))

# args is a hash like { biden: 320, trump: 218 }
def sorted_election_result_string(args)
  args.sort_by(&:last).reverse.map do |candidate, votes|
    "#{candidate.capitalize} #{votes} EVs"
  end.join(", ")
end

if ARGV.include?("--test")
  # randomize winner for testing
  districts.each do |district, data|
    data[:winner] = candidate_names.sample
  end
end

# tally actual voting results
# raise error if missing winner
districts.each do |district_name, data|
  winner = data[:winner]
  raise(RuntimeError, "Missing winner of #{district_name}") unless winner && candidate_names.include?(winner)
  candidates[winner][:votes] ||= 0
  candidates[winner][:votes] += data[:votes]
end
STDOUT.puts "Actual election results: #{sorted_election_result_string(biden: candidates[:biden][:votes], trump: candidates[:trump][:votes])}"
STDOUT.puts

file_paths = Dir.glob(File.join(File.expand_path(directory), "xlsx", "*.xlsx"))

# determine projected votes for each candidate, difference from actual, and number of correctly predicted districts
# according to each contestant's predictions in their respective spreadsheets
contestants = {}
file_paths.each do |file_path|
  contestant = File.basename(file_path).split("-").first.strip
  contestants[contestant] = { biden: 0, trump: 0, num_correct_districts: 0}
  xlsx = Roo::Spreadsheet.open(file_path)
  sheet = xlsx.sheet(0)
  (3..58).each do |row|
    district, votes, projected_winner = sheet.row(row)
    projected_winner_unformatted = projected_winner.gsub(/[^a-z]/i, '').downcase
    candidate = candidates.detect { |cand, options| options[:inputs].include?(projected_winner_unformatted) }
    raise(RuntimeError, "#{contestant} does not have a valid winner for #{district}") unless candidate
    district_data = districts[district]
    contestants[contestant][candidate.first] += district_data[:votes]
    contestants[contestant][:num_correct_districts] += 1 if (candidate.first == district_data[:winner])
  end
  contestants[contestant][:difference] = (contestants[contestant][:biden] - candidates[:biden][:votes]).abs
end

# determine total pot size
total_pot_size = contestants.map { |contestant, data| districts.size - data[:num_correct_districts] }.sum
STDOUT.puts "Total pot size: $#{total_pot_size}"

# determine winner(s) based on smallest difference from actual EV
min_difference = contestants.map { |c, data| data[:difference] }.min
contestants.sort_by { |c, data| data[:difference] }.each do |contestant, data|
  win = data[:difference] == min_difference
  message = "#{contestant} #{win ? "won" : "lost"}, " +
    "predicting #{sorted_election_result_string(biden: data[:biden], trump: data[:trump])}; " + 
    "off by #{data[:difference]} electoral vote(s), " +
    "with #{data[:num_correct_districts]} correctly predicted districts " +
    "and owes $#{districts.size - data[:num_correct_districts]} to pot."
  STDOUT.puts message
end
