# Servicio de resultados de lotería uruguaya.
#
# Scrapea resultados de los principales juegos de azar de La Banca (DNLQ):
#   - 5 de Oro (domingos y miércoles)
#   - Quiniela Nocturna (lunes a sábado)
#   - Quiniela Vespertina (lunes a viernes)
#   - Tómbola Nocturna (lunes a sábado)
#   - Tómbola Vespertina (lunes a viernes)
#
# Fuente de scraping: resultadosorteo.net (agrega resultados oficiales de La Banca)
#
# Estructura HTML:
#   - 5 de Oro: span.bolita.bolita_normal (5 números), span.bolita_extra (1 extra)
#   - Quiniela: div.quiniela_numero > ul > li con formato "01: <span>867</span>"
#   - Tómbola: div.tombola_numero > ul > li con formato similar
class LotteryService
  BASE_URL = 'https://resultadosorteo.net/uruguay'

  GAMES = {
    'cinco_de_oro' => '5-de-oro',
    'quiniela_nocturna' => 'quiniela-nocturna',
    'quiniela_vespertina' => 'quiniela-vespertina',
    'tombola_nocturna' => 'tombola-nocturna',
    'tombola_vespertina' => 'tombola-vespertina'
  }.freeze

  def self.fetch_result(game)
    slug = GAMES[game]
    return nil unless slug

    url = "#{BASE_URL}/#{slug}/"
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    date = extract_date(doc)

    numbers = case game
              when 'cinco_de_oro' then extract_cinco_de_oro(doc)
              when /quiniela/ then extract_quiniela(doc)
              when /tombola/ then extract_tombola(doc)
              end

    return nil unless numbers

    { game:, date:, **numbers }
  end

  def self.available_games
    GAMES.keys
  end

  # --- Métodos privados ---

  def self.extract_date(doc)
    fecha = doc.at_css('.fecha')
    fecha&.text&.strip
  end

  def self.extract_cinco_de_oro(doc)
    container = doc.at_css('.bolitas_uruguay') || doc.at_css('.bolitas')
    return nil unless container

    regular_balls = container.css('.bolita_normal').reject { |b| b['class']&.include?('bolita_extra') }
    extra_ball = container.at_css('.bolita_extra')

    numbers = regular_balls.map { |b| b.text.strip.to_i }
    extra = extra_ball&.text&.strip&.to_i

    { numbers:, extra_number: extra }
  end

  def self.extract_quiniela(doc)
    container = doc.at_css('.quiniela_numero')
    return nil unless container

    results = extract_numbered_list(container)
    { numbers: results }
  end

  def self.extract_tombola(doc)
    container = doc.at_css('.tombola_numero')
    return nil unless container

    results = extract_numbered_list(container)
    { numbers: results }
  end

  def self.extract_numbered_list(container)
    results = {}

    container.css('li').each do |li|
      text = li.text.strip
      match = text.match(/(\d+):\s*(\d+)/)
      next unless match

      position = match[1].to_i
      number = match[2].to_i
      results[position] = number
    end

    results
  end

  private_class_method :extract_date, :extract_cinco_de_oro, :extract_quiniela,
                       :extract_tombola, :extract_numbered_list
end
