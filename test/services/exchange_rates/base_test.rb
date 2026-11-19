require 'test_helper'

class ExchangeRates::BaseTest < ActiveSupport::TestCase
  Base = ExchangeRates::Base

  def doc(html)
    Nokogiri::HTML(html)
  end

  test 'number entiende coma, punto y decimales de más' do
    assert_in_delta 39.4, Base.number('39,40', 'x')
    assert_in_delta 41.8, Base.number('41.8000', 'x')
    assert_in_delta 40.643, Base.number(' 40,643 ', 'x')
  end

  test 'number rechaza valores que no pueden ser un dólar' do
    ['0,00', '', nil, '0.02', '446.30'].each do |value|
      assert_raises(Base::ParseError) { Base.number(value, 'x') }
    end
  end

  test 'row encuentra la fila en tablas, columnas pegadas de Wix y con guion en el medio' do
    assert_equal %w[38,90 41,40], Base.row(doc('<p>Dólar Americano 38,90 41,40</p>'), 'dolar(?: americano)?', 'x')
    assert_equal %w[39.40 41.80], Base.row(doc('<tr><td>DÓLAR</td><td>39.40</td><td>41.80</td></tr>'), 'dolar', 'x')
    assert_equal %w[39.40 41.80],
                 Base.row(doc('<table><tr><td>dolar</td><td>39.40</td><td>-</td><td>41.80</td></tr></table>'), 'dolar',
                          'x')
  end

  test 'row no confunde el dolar de pizarra con otra fila que empieza igual' do
    html = '<div><p>Dólar 39,40 41,80</p><p>Dólar finza 40,05 40,95</p></div>'

    assert_equal %w[39,40 41,80], Base.row(doc(html), 'dolar', 'x')
    assert_equal %w[40,05 40,95], Base.row(doc(html), 'dolar finza', 'x')
  end

  test 'row levanta si la pagina cambio y no esta la fila' do
    assert_raises(Base::ParseError) { Base.row(doc('<p>Euro 42,00 46,00</p>'), 'dolar', 'x') }
  end

  test 'rate arma la forma comun' do
    rate = Base.rate(source: 'varlix', name: 'Varlix', kind: 'counter', buy: '38,90', sell: '41,40', url: 'u')

    assert_equal(
      { source: 'varlix', name: 'Varlix', kind: 'counter', currency: 'USD', buy: 38.9, sell: 41.4, url: 'u' }, rate
    )
    assert_raises(ArgumentError) { Base.rate(source: 'x', name: 'x', kind: 'otro', buy: '40', sell: '41', url: 'u') }
  end
end
