require 'test_helper'
require 'minitest/mock'

class ExchangeRatesTest < ActiveSupport::TestCase
  test 'si una fuente falla, devuelve el resto y el error de esa' do
    ok = [{ source: 'varlix', buy: 38.9 }]
    fetch = ->(source) { source == 'gales' ? raise(Scraper::BlockedError, 'gales respondió 403') : ok }

    ExchangeRates.stub(:fetch, fetch) do
      result = ExchangeRates.fetch_all

      assert_equal({ 'gales' => 'gales respondió 403' }, result[:errors])
      assert_equal ExchangeRates::SOURCES.size - 1, result[:rates].size
    end
  end
end
