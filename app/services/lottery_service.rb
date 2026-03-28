# frozen_string_literal: true

# Servicio de resultados de lotería uruguaya.
#
# Scrapea resultados de los principales juegos de azar desde la DNLQ (loteria.gub.uy):
#   - Quiniela Nocturna (lunes a sábado)
#   - Quiniela Vespertina (lunes a viernes)
#   - Tómbola Nocturna (lunes a sábado)
#   - Tómbola Vespertina (lunes a viernes)
#
# Fuente: https://www.loteria.gub.uy/ver_resultados.php
class LotteryService
  DNLQ_BASE_URL = 'https://www.loteria.gub.uy'

  GAMES = %w[
    quiniela_nocturna
    quiniela_vespertina
    tombola_nocturna
    tombola_vespertina
  ].freeze

  class << self
    def fetch_result(game)
      return nil unless GAMES.include?(game)

      case game
      when 'quiniela_nocturna', 'quiniela_vespertina'
        fetch_dnlq_quiniela(game)
      when 'tombola_nocturna', 'tombola_vespertina'
        fetch_dnlq_tombola(game)
      end
    end

    def available_games
      GAMES
    end

    private

    # ── Quiniela / Tómbola (DNLQ - loteria.gub.uy) ─────────────────

    def fetch_dnlq_page
      yesterday = Time.now.in_time_zone('America/Montevideo').to_date - 1
      url = "#{DNLQ_BASE_URL}/ver_resultados.php?vdia=#{yesterday.day}&vmes=#{yesterday.month}&vano=#{yesterday.year}"
      response = HTTParty.get(url, headers: { 'User-Agent' => 'Mozilla/5.0' })
      return nil unless response.success?

      Nokogiri::HTML(response.body)
    end

    def find_dnlq_section(doc, game)
      turno = game.include?('vespertina') ? 'VESPERTINA' : 'NOCTURNO'
      header = doc.at_css("img[alt*='QUINIELA Y TOMBOLA #{turno}']")
      return nil unless header

      header.ancestors('table').find { |t| t.css("img[src*='numeros_tablas']").any? }
    end

    def extract_dnlq_date(section)
      section.at_css("img[src*='cabezal_quiniela']")&.parent&.text&.strip&.gsub(/\s+/, ' ')
    end

    def extract_dnlq_turno(game)
      game.include?('vespertina') ? 'Sorteo Vespertino' : 'Sorteo Nocturno'
    end

    def fetch_dnlq_quiniela(game)
      doc = fetch_dnlq_page
      return nil unless doc

      section = find_dnlq_section(doc, game)
      return nil unless section

      numbers = {}
      section.css("img[src*='numeros_tablas/l_']").each do |img|
        pos = img['src'].match(/l_(\d+)\.gif/)&.[](1)&.to_i
        next unless pos

        td = img.ancestors('td').first
        number_td = td
        while number_td = number_td.next_element
          value = number_td.at_css('div.text_azul_3')&.text&.strip
          if value && !value.empty?
            numbers[pos] = value.to_i
            break
          end
        end
      end

      return nil if numbers.empty?

      { game:, date: extract_dnlq_date(section), turno: extract_dnlq_turno(game), numbers: }
    end

    def fetch_dnlq_tombola(game)
      doc = fetch_dnlq_page
      return nil unless doc

      section = find_dnlq_section(doc, game)
      return nil unless section

      tombola_table = section.css("table[cellspacing='5']").first
      return nil unless tombola_table

      numbers = tombola_table.css('div.text_azul_3').map { |div| div.text.strip.to_i }
      return nil if numbers.empty?

      { game:, date: extract_dnlq_date(section), turno: extract_dnlq_turno(game), numbers: }
    end
  end
end
