# frozen_string_literal: true

# Servicio de resultados de lotería uruguaya.
#
# Scrapea resultados de los principales juegos de azar de La Banca (DNLQ):
#   - 5 de Oro (domingos y miércoles)
#   - Quiniela Nocturna (lunes a sábado)
#   - Quiniela Vespertina (lunes a viernes)
#   - Tómbola Nocturna (lunes a sábado)
#   - Tómbola Vespertina (lunes a viernes)
#
# Fuente de scraping: https://www3.labanca.com.uy
#
# Estructura:
#   - 5 de Oro: GET /resultados/cincodeoro (panel-izquierdo)
#   - Quiniela/Tómbola: POST /resultados/{game}/renderizar_info_sorteo (AJAX)
class LotteryService
  BASE_URL = 'https://www3.labanca.com.uy'

  GAMES = {
    'cinco_de_oro' => 'resultados/cincodeoro',
    'quiniela_nocturna' => 'resultados/quiniela/renderizar_info_sorteo',
    'quiniela_vespertina' => 'resultados/quiniela/renderizar_info_sorteo',
    'tombola_nocturna' => 'resultados/tombola/renderizar_info_sorteo',
    'tombola_vespertina' => 'resultados/tombola/renderizar_info_sorteo'
  }.freeze

  PANEL_SELECTOR = '#panel-izquierdo'
  VESPERTINA_HOUR = '15:00'
  NOCTURNA_HOUR = '21:00'
  AJAX_RESPONSE_REGEX = /\$\('#{PANEL_SELECTOR}'\)\.html\("(.+?)"\);/.freeze

  FIRST_ROW_INDEX = 0
  SECOND_ROW_INDEX = 1
  POZO_ORO_INDEX = 0
  POZO_PLATA_INDEX = 1
  POZO_MONTOS_INDEX = 1
  POZO_REVANCHA_INDEX = 3

  class << self
    def fetch_result(game)
      return nil unless GAMES.key?(game)

      case game
      when 'cinco_de_oro'
        fetch_cinco_de_oro_result
      when 'quiniela_nocturna', 'quiniela_vespertina'
        fetch_quiniela_result(game)
      when 'tombola_nocturna', 'tombola_vespertina'
        fetch_tombola_result(game)
      end
    end

    def available_games
      GAMES.keys
    end

    private

    # Cinco de Oro
    def fetch_cinco_de_oro_result
      url = "#{BASE_URL}/#{GAMES['cinco_de_oro']}"
      response = HTTParty.get(url)
      return nil unless response.success?

      doc = Nokogiri::HTML(response.body)

      date = doc.at_css("#{PANEL_SELECTOR} h2")&.text&.strip
      numbers = extract_cinco_de_oro(doc)
      return nil unless numbers

      { game: 'cinco_de_oro', date:, **numbers }
    end

    def extract_cinco_de_oro(doc)
      container = doc.at_css(PANEL_SELECTOR)
      return nil unless container

      {
        **extract_pozos(container),
        **extract_primera_vuelta(container),
        **extract_revancha(container)
      }
    end

    def extract_pozos(container)
      pozo_columns = container.css('.row')[FIRST_ROW_INDEX].css('.columns.pozo')
      montos = pozo_columns[POZO_MONTOS_INDEX].css('span.monto-pozo').map { |span| span.text.strip }

      {
        pozo_oro: montos[POZO_ORO_INDEX],
        pozo_plata: montos[POZO_PLATA_INDEX],
        pozo_revancha: extract_pozo_revancha(container)
      }
    end

    def extract_pozo_revancha(container)
      pozo_revancha_element = container.css('.columns.pozo')[POZO_REVANCHA_INDEX]
      pozo_revancha_element&.next_element&.at_css('span.monto-pozo')&.text&.strip
    end

    def extract_primera_vuelta(container)
      bolillas_container = container.css('.row')[SECOND_ROW_INDEX].at_css('.bolillas')

      {
        numeros_primera_vuelta: extract_regular_numbers(bolillas_container),
        numero_extra: extract_extra_number(bolillas_container)
      }
    end

    def extract_revancha(container)
      bolillas_revancha = container.css('.row').last.at_css('.bolillas')

      {
        numeros_revancha: extract_regular_numbers(bolillas_revancha) || [],
        numero_extra_revancha: extract_extra_number(bolillas_revancha)
      }
    end

    def extract_regular_numbers(bolillas_container)
      bolillas_container&.css('li:not(.extra):not(.caption) img')&.map { |img| img['alt'].to_i }
    end

    def extract_extra_number(bolillas_container)
      bolillas_container&.at_css('li.extra img')&.[]('alt')&.to_i
    end

    # Quiniela
    def fetch_quiniela_result(game)
      fetch_ajax_result(game, :extract_quiniela)
    end

    def extract_quiniela(doc)
      numbers = doc.css('ul.results-column li').each_with_object({}) do |li, results|
        span = li.at_css('span')
        next unless span

        position = span.text.strip.delete('.').to_i
        number = li.text.gsub(span.text, '').strip.to_i

        results[position] = number
      end

      { numbers: }
    end

    # Tómbola
    def fetch_tombola_result(game)
      fetch_ajax_result(game, :extract_tombola)
    end

    def extract_tombola(doc)
      numbers = doc.css('ul.results-column li').map { |li| li.text.strip.to_i }

      { numbers: }
    end

    # Helpers
    def fetch_ajax_result(game, extractor_method)
      doc = fetch_ajax_sorteo(game, GAMES[game])
      return nil unless doc

      date = doc.at_css('h2')&.text&.strip
      turno = doc.at_css('h3')&.text&.strip
      numbers = send(extractor_method, doc)
      return nil unless numbers

      { game:, date:, turno:, **numbers }
    end

    def fetch_ajax_sorteo(game, endpoint)
      yesterday = Date.today - 1
      hora = game.include?('vespertina') ? VESPERTINA_HOUR : NOCTURNA_HOUR
      fecha_sorteo = "#{yesterday.strftime('%Y-%m-%d')}-#{hora}"

      url = "#{BASE_URL}/#{endpoint}"
      response = HTTParty.post(url,
        body: { fecha_sorteo: },
        headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      )

      return nil unless response.success?

      html_match = response.body.match(AJAX_RESPONSE_REGEX)
      return nil unless html_match

      html_content = unescape_js_html(html_match[1])
      Nokogiri::HTML(html_content)
    end

    def unescape_js_html(escaped_html)
      escaped_html
        .gsub('\/', '/')
        .gsub('\\n', "\n")
        .gsub('\\"', '"')
    end
  end
end
