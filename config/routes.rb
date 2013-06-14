GeoTweet::Application.routes.draw do
  resources :geo_locations, :only => [:create, :index] do
    collection do
      get 'search'
    end
  end
  root :to => "geo_locations#search"
  
end
