require 'csv'
require 'open-uri'
namespace :import do 
  desc "Import HSK characters level 2 through 6"
  task :hsk2_6 => :environment do 
    # csv_text = File.read('hsk6.csv')
    csv_text = open("https://dl.dropboxusercontent.com/s/gk2pa4ld92xijr8/hsk6.csv?token_hash=AAEJV9T38Ot65MgUFBs0zigfqgUzPzLaHMakfzyxiONqVQ&dl=1") { |f| f.read }
    csv = CSV.parse(csv_text, :headers => true)
    csv_ordered = csv.to_a[2..-11].sort{|a,b| a[0].to_i <=> b[0].to_i} #  Skip header and empty bottom rows, order by level
    csv_ordered.each do |row| #
      if row[0].to_i > 1 # Level 2 and above
        row[1].each_char do |character|
          unless Character.find_by simplified: character
            Character.create(simplified: character, level: row[0].to_i)
          end
        end
      end
    end
  end
end
