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
        get 'schedules'
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

      scope 'news', controller: 'news', as: 'news' do
        get 'headlines'
      end

      scope 'grain', controller: 'grain', as: 'grain' do
        get 'prices'
      end

      scope 'cattle', controller: 'cattle', as: 'cattle' do
        get 'prices'
      end

      scope 'salary', controller: 'salary', as: 'salary' do
        get 'net'
      end

      scope 'tolls', controller: 'tolls', as: 'tolls' do
        get 'prices'
      end

      scope 'economy', controller: 'economy', as: 'economy' do
        get 'values'
      end

      scope 'inflation', controller: 'inflation', as: 'inflation' do
        get 'indicators'
      end

      scope 'supermarkets', controller: 'supermarkets', as: 'supermarkets' do
        get 'food_basket', to: 'supermarkets#food_basket'
        get 'food_basket/:store', to: 'supermarkets#food_basket_store'
        get 'food_basket/:store/:product', to: 'supermarkets#food_basket_store_product'
      end
    end
  end
end

