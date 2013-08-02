FactoryGirl.define do
  factory :character do |c|
    c.simplified "人"
  end
  
  factory :radical do |r|
    r.simplified "人"
    r.position 9
    r.variant false
  end
  
  factory :admin do |s|
    s.email    "sjors@purpledunes.com"
    s.password "secret1234"
  end
end