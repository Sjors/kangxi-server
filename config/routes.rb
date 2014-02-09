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
  get 'lookup/radical/:id/more/characters' => 'lookup#first_radical_more_characters', :as => "first_radical_lookup_more_characters"
  
  
  get 'lookup/radical/:id' => 'lookup#first_radical', :as => "first_radical_lookup"
  get 'lookup/radical/:first_id/:second_id' => 'lookup#second_radical', :as => "second_radical_lookup"
  
  get 'lookup/more' => 'lookup#index_more', :as => 'more_radicals'
  get 'lookup/more/more' => 'lookup#index_more_more', :as => 'more_more_radicals'
  get 'lookup/more/more/characters' => 'lookup#index_more_more_characters', :as => 'more_more_radicals_characters'
  
  get 'words/:id/pronunciation.mp3' => 'words#pronunciation',  :as => 'word_pronunciation'
  
  root :to => 'home#index'
  
  devise_for :users, :path_prefix => 'd' 
end
