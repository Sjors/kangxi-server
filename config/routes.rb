ChineseCharacterLookup::Application.routes.draw do
  resources :radicals

  resources :characters
  
  root :to => 'visitors#new'
end
