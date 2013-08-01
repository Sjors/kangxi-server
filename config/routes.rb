RailsBootstrap::Application.routes.draw do
  resources :characters
  
  root :to => 'visitors#new'
end
