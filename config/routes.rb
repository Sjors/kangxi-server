KangxiRadicals::Application.routes.draw do
  resources :radicals

  resources :characters do
    member do 
      post :add_radical
      delete :remove_radical
    end
  end
  
  root :to => 'visitors#new'
  
  devise_for :users, :path_prefix => 'd' 
end
