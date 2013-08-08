KangxiRadicals::Application.routes.draw do
  resources :radicals

  resources :characters do
    member do 
      post :add_radical
      delete :remove_radical
    end
  end
  
  get 'lookup' => 'lookup#index'
  get 'lookup/radical/:id' => 'lookup#radical', :as => "radical_lookup"
  
  
  root :to => 'lookup#index'
  
  devise_for :users, :path_prefix => 'd' 
end
