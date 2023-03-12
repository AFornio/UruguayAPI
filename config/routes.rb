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
    end
  end
  # Defines the root path route ("/")
  # root "articles#index"
end

