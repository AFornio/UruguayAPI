require 'test_helper'
require 'webmock/minitest'

class Api::V1::BanksBenefitsControllerTest < ActionDispatch::IntegrationTest
  test 'devuelve los beneficios del banco pedido' do
    stub_request(:get, BankBenefits::Scotiabank::URL).to_return(body: <<~HTML)
      <script> pushBenefit({ dias: 'Todos los días', desde: '2026-01-01', hasta: '2099-01-01', titulo: 'Disco',
        descuentos: [ { pct: '20%', texto: 'off' } ] }); </script>
    HTML

    get api_v1_banks_benefits_path(bank: 'scotiabank')

    assert_response :success
    assert_equal([['scotiabank', 'Disco', 20]], response.parsed_body.map do |b|
      b.values_at('bank', 'merchant', 'discount')
    end)
  end

  test 'banco desconocido da 404' do
    get api_v1_banks_benefits_path(bank: 'kernel')

    assert_response :not_found
  end
end
