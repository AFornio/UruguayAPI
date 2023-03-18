Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      scope 'ci', controller: 'ci', as: 'ci' do
        get 'validate'
        get 'validate_digit'
        get 'random'
      end

      scope 'rates', controller: 'rates', as: 'rates' do
        get 'index'
      end

      scope 'buses', controller: 'buses', as: 'buses' do
        get 'options'
        get 'schedules'
        get 'all_schedules'
      end

      scope 'gasoline', controller: 'gasoline', as: 'gasoline' do
        get 'index'
        get ':name', to: 'gasoline#show'
      end

      scope 'holidays', controller: 'holidays', as: 'holidays' do
        get ':year', to: 'holidays#show'
        get 'official/:year', to: 'holidays#official'
        get 'official_and_non_working/:year', to: 'holidays#official_and_non_working'
        get 'holidays_and_observances/:year', to: 'holidays#holidays_and_observances'
        get 'holidays_and_observances_including_locals/:year', to: 'holidays#holidays_and_observances_including_locals'
      end
      
      scope 'billboard', controller: 'billboard', as: 'billboard' do
        get 'index'
        get ':event_type', to: 'billboard#show'
      end
    end
  end
  # Defines the root path route ("/")
  # root "articles#index"
end

