json.array!(@radicals) do |radical|
  json.extract! radical, :position, :simplified, :variant
  json.url radical_url(radical, format: :json)
end
