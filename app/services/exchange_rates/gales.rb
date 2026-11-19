# Gales: el histórico de su página de cotizaciones (admin-ajax de WordPress, con el nonce
# del formulario). Se pide la última semana y se toma el último día con cotización: a la
# noche la web ya muestra el día siguiente en 0.
module ExchangeRates
  class Gales
    PAGE = 'https://www.gales.com.uy/cotizaciones/'.freeze
    AJAX_URL = 'https://www.gales.com.uy/wp-admin/admin-ajax.php'.freeze
    DOLLAR = '2222'.freeze

    class << self
      def fetch_all
        latest = history.reverse.find { |day| day['compra'].to_f.positive? }
        raise Base::ParseError, 'gales: sin cotizaciones en la última semana' if latest.nil?

        [Base.rate(source: 'gales', name: 'Gales', kind: 'counter', buy: latest['compra'], sell: latest['venta'],
                   url: PAGE)]
      end

      private

      def history
        nonce = Scraper.html(PAGE).at_css('form[name="monedas-form"] input[name="_wpnonce"]')&.[]('value')
        response = Scraper.post(AJAX_URL, body: {
                                  _wpnonce: nonce, action: 'currency_history', form: 'monedas-form', moneda: DOLLAR,
                                  'fecha-inicio': (Base.today - 7).iso8601, 'fecha-final': Base.today.iso8601,
                                  formato: 'tabla'
                                })
        JSON.parse(response.body).fetch('data', [])
      end
    end
  end
end
