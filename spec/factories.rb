FactoryGirl.define do
  factory :character do |c|
    c.simplified "人"
  end
  
  factory :radical do |r|
    r.simplified "亻"
    r.position 9
    r.variant true
  end
end