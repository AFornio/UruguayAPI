Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      scope 'ci', controller: 'ci', as: 'ci' do
        get 'validate'
        get 'validate_digit'
        get 'random'
      end

      scope 'banks', controller: 'banks', as: 'banks' do
        get 'brou_rates'
        get 'brou_benefits'
      end

      scope 'buses', controller: 'buses', as: 'buses' do
        get 'options'
        get 'schedules'
        get 'all_schedules'
      end

      scope 'gasoline', controller: 'gasoline', as: 'gasoline' do
        get 'ancap_rates'
        get ':name', to: 'gasoline#show'
      end

      scope 'holidays', controller: 'holidays', as: 'holidays' do
        root 'holidays#index'
      end

      scope 'events', controller: 'events', as: 'events' do
        get 'billboard', to: 'events#billboard'
        get 'billboard/:event_type', to: 'events#billboard_event'
        get 'antel_arena'
      end

      scope 'horoscope', controller: 'horoscope', as: 'horoscope' do
        get 'today'
      end
    end
  end
end

