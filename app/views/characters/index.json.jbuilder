json.array!(@characters) do |character|
  json.extract! character, :simplified
  json.url character_url(character, format: :json)
end
