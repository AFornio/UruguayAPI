require 'test_helper'
require 'webmock/minitest'

class BankBenefits::BbvaTest < ActiveSupport::TestCase
  LIST = 'https://www.bbva.com.uy/personas/productos/tarjetas/descuentos'.freeze

  def card(slug, name)
    <<~HTML
      <article class="card__base promocard__base">
        <img class="card__img" src="/content/dam/#{slug}.jpg?imwidth=320">
        <div class="promocard__category">Gastronomía</div>
        <p class="card__preheadline">Restaurante en Solís, Maldonado</p>
        <h3 class="card__title">#{name}</h3>
        <div class="promocard__tag">
          <span>Tarjeta de Crédito, </span><span>En la Zona, </span><span>Maldonado, </span><span>Tarjeta de Débito</span>
        </div>
        <a class="card__link" href="/personas/productos/tarjetas/descuentos/gastronomia/#{slug}.html">Quiero saber más</a>
      </article>
    HTML
  end

  def detail(vigencia)
    <<~HTML
      <div class="promodetail__text"><h3>Vigencia: #{vigencia}</h3>
        <ul><li>20% Off con Tarjetas de Débito</li><li>30% Off con Tarjetas Platinum</li></ul>
        <p>Local:</p><ul><li>Av. Barreira 28</li></ul></div>
    HTML
  end

  setup do
    stub_request(:get, %r{#{LIST}/[\w-]+\.html\z}).to_return(body: '')
    stub_request(:get, "#{LIST}/gastronomia.html")
      .to_return(body: "#{card('lo-de-jaime', 'Lo de Jaime')}<div class=\"pagination__pages\"> 1 de 2 </div>")
    stub_request(:get, "#{LIST}/gastronomia.pag-2.html").to_return(body: card('viejo', 'Viejo'))
    stub_request(:get, "#{LIST}/gastronomia/lo-de-jaime.html").to_return(body: detail('31 de Diciembre 2099'))
    stub_request(:get, "#{LIST}/gastronomia/viejo.html").to_return(body: detail('1 de enero de 2020'))
  end

  test 'recorre las paginas, lee el detalle y descarta los vencidos' do
    benefits = BankBenefits::Bbva.fetch_all
    jaime = benefits.sole

    assert_equal 'Lo de Jaime', jaime[:merchant]
    assert_equal 30, jaime[:discount]
    assert_equal '2099-12-31', jaime[:valid_until]
    assert_equal ['Tarjeta de Crédito', 'Tarjeta de Débito'], jaime[:cards]
    assert_equal ['Maldonado'], jaime[:departments]
    assert_equal 'https://www.bbva.com.uy/content/dam/lo-de-jaime.jpg', jaime[:logo]
    assert_equal "#{LIST}/gastronomia/lo-de-jaime.html", jaime[:url]
  end

  test 'lee la vigencia con y sin "de" antes del año y con espacio duro' do
    stub_request(:get, "#{LIST}/gastronomia/lo-de-jaime.html").to_return(body: detail("31 de\u00A0Octubre 2099"))
    stub_request(:get, "#{LIST}/gastronomia/viejo.html").to_return(body: detail('5 de enero de 2099'))

    assert_equal(%w[2099-10-31 2099-01-05], BankBenefits::Bbva.fetch_all.map { |b| b[:valid_until] })
  end
end
