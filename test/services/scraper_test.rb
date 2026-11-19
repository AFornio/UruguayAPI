require 'test_helper'
require 'webmock/minitest'
require 'minitest/mock'

class ScraperTest < ActiveSupport::TestCase
  test 'get reintenta un 403 y levanta si sigue bloqueado' do
    stub_request(:get, 'https://banco.uy/x').to_return(status: 403).times(3).then.to_return(status: 403)

    Scraper.stub(:sleep, nil) do
      error = assert_raises(Scraper::BlockedError) { Scraper.get('https://banco.uy/x') }
      assert_match '403', error.message
    end
    assert_requested :get, 'https://banco.uy/x', times: Scraper::RETRIES + 1
  end

  test 'get no reintenta un 404 y devuelve la respuesta si se recupera' do
    stub_request(:get, 'https://banco.uy/no').to_return(status: 404)
    stub_request(:get, 'https://banco.uy/ok').to_return({ status: 503 }, { status: 200, body: 'ok' })

    Scraper.stub(:sleep, nil) do
      assert_raises(Scraper::BlockedError) { Scraper.get('https://banco.uy/no') }
      assert_equal 'ok', Scraper.get('https://banco.uy/ok').body
    end
    assert_requested :get, 'https://banco.uy/no', times: 1
  end

  test 'post manda el body y el User-Agent de navegador' do
    stub_request(:post, 'https://banco.uy/form').with(body: { 'a' => '1' },
                                                      headers: { 'User-Agent' => Scraper::USER_AGENT })
                                                .to_return(body: 'ok')

    assert_equal 'ok', Scraper.post('https://banco.uy/form', body: { 'a' => '1' }).body
  end
end
