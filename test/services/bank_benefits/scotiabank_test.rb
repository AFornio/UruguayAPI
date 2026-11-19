require 'test_helper'
require 'webmock/minitest'

class BankBenefits::ScotiabankTest < ActiveSupport::TestCase
  def push(title, dias, desde, hasta, extra = '')
    <<~HTML
      <script> pushBenefit({ categoria: 'restaurantes,cafeteria', departamento: 'Montevideo', dias: '#{dias}',
        desde: '#{desde}', hasta: '#{hasta}', titulo: '#{title}', imagen: 'img.jpg', logo: 'logo.jpg', orden: 1,
        #{extra}
        descuentos: [ { pct: '25% de ahorro', texto: 'con Platinum.' }, { pct: '15% de ahorro', texto: 'con crédito.' } ],
        legal: 'Válido de lunes a domingo, no aplica en Mc Donald\\'s' }); </script>
    HTML
  end

  setup do
    html = push('La Pasiva', 'Todos los días', '2026-01-01', '2099-01-01', "link: 'https://scotia.uy/pasiva',") +
           push("Cafe d\\'Paris", 'custom:Jueves y Domingos', '2026-01-01', '2099-01-01') +
           push('Vencido', 'Todos los días', '2020-01-01', '2020-02-01')
    stub_request(:get, BankBenefits::Scotiabank::URL).to_return(body: html)
  end

  test 'lee los objetos inline, saca los vencidos y entiende dias custom' do
    pasiva, paris = BankBenefits::Scotiabank.fetch_all

    assert_equal ['La Pasiva', "Cafe d'Paris"], [pasiva[:merchant], paris[:merchant]]
    assert_equal 25, pasiva[:discount]
    assert_equal 'Restaurantes', pasiva[:category]
    assert_equal ['Montevideo'], pasiva[:departments]
    assert_equal (1..7).to_a, pasiva[:weekdays]
    assert_equal 'https://scotia.uy/pasiva', pasiva[:url]
    assert_equal [4, 7], paris[:weekdays]
    assert_equal BankBenefits::Scotiabank::URL, paris[:url]
  end
end
