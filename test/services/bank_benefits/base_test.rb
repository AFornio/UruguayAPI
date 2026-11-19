require 'test_helper'

class BankBenefits::BaseTest < ActiveSupport::TestCase
  Base = BankBenefits::Base

  test 'discount toma el mayor porcentaje' do
    assert_equal 25, Base.discount('25% y 15% menos en San Roque')
    assert_equal 30, Base.discount("20% Off con Débito\n30% Off con Platinum")
    assert_nil Base.discount('2x1 en Movie')
    assert_nil Base.discount(nil)
  end

  test 'weekdays entiende todos los días, rangos, listas y plurales' do
    assert_equal (1..7).to_a, Base.weekdays('15% de descuento todos los días.')
    assert_equal [1, 2, 3, 4, 5], Base.weekdays('20% de dto de lunes a viernes')
    assert_equal [2, 4], Base.weekdays('25% los días martes y jueves')
    assert_equal [3], Base.weekdays('Los miércoles')
    assert_equal [4, 7], Base.weekdays('Jueves y Domingos')
    assert_equal [6, 7], Base.weekdays('los fines de semana')
    assert_equal [], Base.weekdays('25% con Platinum')
  end

  test 'active? respeta desde y hasta' do
    today = Date.new(2026, 11, 18)
    assert Base.active?('2026-11-01', '2026-11-30', today:)
    assert Base.active?(nil, nil, today:)
    assert_not Base.active?('2026-12-01', nil, today:)
    assert_not Base.active?(nil, '2026-11-17', today:)
  end

  test 'benefit arma la forma comun y limpia el html' do
    benefit = Base.benefit(bank: 'x', merchant: ' Disco ', description: '<p>20% los <b>martes</b></p>', url: 'u')

    assert_equal 'Disco', benefit[:merchant]
    assert_equal '20% los martes', benefit[:description]
    assert_equal 20, benefit[:discount]
    assert_equal [2], benefit[:weekdays]
    assert_equal [], benefit[:cards]
  end
end
