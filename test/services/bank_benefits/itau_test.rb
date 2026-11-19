require 'test_helper'
require 'webmock/minitest'

class BankBenefits::ItauTest < ActiveSupport::TestCase
  LANDING = 'https://www.itau.com.uy/inst/restaurantes.html'.freeze

  XML = <<~XML.freeze
    <inicio>
      <list_paquete_personal nombre="Paquete Personal Bank">
        <item final_item="true" id="benef_1">
          <titulo><![CDATA[25% y 15% menos en San Roque]]></titulo>
          <descripcion><![CDATA[<span>25% menos los días martes y jueves.</span>]]></descripcion>
          <final_item id="final_9"><img_logo>sanroque.jpg</img_logo><bases>legal</bases></final_item>
        </item>
      </list_paquete_personal>
      <list_credito nombre="Tarjeta Crédito">
        <item final_item="true" id="benef_1">
          <titulo><![CDATA[25% y 15% menos en San Roque]]></titulo>
          <descripcion/>
          <final_item id="final_9"/>
        </item>
        <item final_item="false" id="benef_2" url="true">
          <titulo><![CDATA[15% menos en restaurantes]]></titulo>
          <url>#{LANDING}</url>
        </item>
      </list_credito>
    </inicio>
  XML

  HTML = <<~HTML.freeze
    <section id="tab-mvd">
      <h2 class="text-2xl">Restaurantes</h2>
      <p class="text-5xl">15% menos</p><p><span>Todos los días,</span> con crédito.</p>
      <div class="aspect-video" title="Baco"><img src="baco.webp"></div>
    </section>
    <section id="tab-interior">
      <h2 class="text-2xl">Restaurantes</h2>
      <p class="text-5xl">20% menos</p><p>Los viernes.</p>
      <h2 class="text-xl">Colonia</h2>
      <div class="aspect-video" title="Anita"><img src="anita.webp"></div>
    </section>
  HTML

  setup do
    stub_request(:get, BankBenefits::Itau::XML_URL).to_return(body: XML)
    stub_request(:get, LANDING).to_return(body: HTML)
  end

  test 'agrupa el mismo beneficio de varios paquetes y abre las landings en comercios' do
    san_roque, baco, anita = BankBenefits::Itau.fetch_all

    assert_equal 'San Roque', san_roque[:merchant]
    assert_equal ['Paquete Personal Bank', 'Tarjeta Crédito'], san_roque[:cards]
    assert_equal [2, 4], san_roque[:weekdays]
    assert_equal 'https://www.itau.com.uy/inst/beneficios.html#/final_item-final_9-benef_1', san_roque[:url]
    assert_equal 'https://www.itau.com.uy/inst/aci/images/sanroque.jpg', san_roque[:logo]

    assert_equal ['Baco', 15, (1..7).to_a, ['Montevideo']],
                 baco.values_at(:merchant, :discount, :weekdays, :departments)
    assert_equal ['Anita', 20, [5], ['Colonia']], anita.values_at(:merchant, :discount, :weekdays, :departments)
    assert_equal LANDING, anita[:url]
  end
end
