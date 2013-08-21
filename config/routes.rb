KangxiRadicals::Application.routes.draw do
  resources :radicals

  resources :characters do
    member do 
      post :add_radical
      delete :remove_radical
    end
  end
  
  get 'lookup' => 'lookup#index'
  get 'lookup/radical/:id/more' => 'lookup#first_radical_more', :as => "first_radical_lookup_more"
  
  get 'lookup/radical/:id' => 'lookup#first_radical', :as => "first_radical_lookup"
  get 'lookup/radical/:first_id/:second_id' => 'lookup#second_radical', :as => "second_radical_lookup"
  
  get 'lookup/more' => 'lookup#index_more', :as => 'more_radicals'
  
  
  root :to => 'lookup#index'
  
  devise_for :users, :path_prefix => 'd' 
end
