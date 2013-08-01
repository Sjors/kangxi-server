ChineseCharacterLookup::Application.routes.draw do
  resources :radicals

  resources :characters
  
  root :to => 'visitors#new'
  
  devise_for :users, :path_prefix => 'd' 
end
