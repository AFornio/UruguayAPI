require 'test_helper'
require 'webmock/minitest'

class BankBenefits::SantanderTest < ActiveSupport::TestCase
  def teaser(id, title, body)
    <<~HTML
      <article data-history-node-id="#{id}" class="node node--type-beneficios node--view-mode-teaser">
        <div class="field--name-field-company-logo"><img src="/sites/default/files/#{id}.png"></div>
        <h3><span class="field field--name-title">#{title}</span></h3>
        <div class="field--name-body"><p>#{body}</p></div>
        <a class="use-ajax" href="/beneficios/#{title.parameterize}">Ver más detalles</a>
      </article>
    HTML
  end

  setup do
    all = teaser(1, 'Disco', '20% los martes') + teaser(2, 'Bruta', '25% con Platinum.<br />15% con crédito.')
    stub_request(:get, BankBenefits::Santander::URL).to_return(body: all + teaser(1, 'Disco', '20% los martes'))
    stub_request(:get, /categoria/).to_return(body: '')
    stub_request(:get, "#{BankBenefits::Santander::URL}?categoria%5B21%5D=21").to_return(body: teaser(1, 'Disco', 'x'))
  end

  test 'lee todos los beneficios sin repetir y les pone el rubro' do
    disco, bruta = BankBenefits::Santander.fetch_all

    assert_equal %w[Disco Bruta], [disco[:merchant], bruta[:merchant]]
    assert_equal 'Supermercados', disco[:category]
    assert_equal 'Otros', bruta[:category]
    assert_equal [2], disco[:weekdays]
    assert_equal 25, bruta[:discount]
    assert_equal 'https://www.santander.com.uy/beneficios/disco', disco[:url]
    assert_equal 'https://www.santander.com.uy/sites/default/files/1.png', disco[:logo]
  end
end
