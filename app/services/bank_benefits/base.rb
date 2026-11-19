# Piezas comunes a los scrapers de beneficios de bancos.
#
# Cada banco devuelve una lista de hashes con la misma forma (ver .benefit), así la app
# puede responder "¿qué descuento tengo hoy?" sin saber de qué banco viene cada uno.
module BankBenefits
  module Base
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                 '(KHTML, like Gecko) Chrome/130 Safari/537.36'.freeze
    TIMEOUT = 30
    THREADS = 8

    # Lunes = 1 ... domingo = 7 (ISO 8601, igual que Date#cwday).
    WEEKDAYS = {
      'lunes' => 1, 'martes' => 2, 'miercoles' => 3, 'jueves' => 4,
      'viernes' => 5, 'sabado' => 6, 'domingo' => 7
    }.freeze
    ALL_WEEK = (1..7).to_a.freeze
    DEPARTMENTS = [
      'Artigas', 'Canelones', 'Cerro Largo', 'Colonia', 'Durazno', 'Flores', 'Florida', 'Lavalleja',
      'Maldonado', 'Montevideo', 'Paysandú', 'Río Negro', 'Rivera', 'Rocha', 'Salto', 'San José',
      'Soriano', 'Tacuarembó', 'Treinta y Tres'
    ].freeze
    DAY_WORD = /\b(lunes|martes|miercoles|jueves|viernes|sabados?|domingos?)\b/

    module_function

    RETRIES = 3
    RETRY_ON = [403, 429, 500, 502, 503, 504].freeze

    # Reintenta con espera creciente: BBVA corta con 403 si se le pide rápido.
    def get(url, headers: {})
      (0..RETRIES).each do |attempt|
        response = HTTParty.get(url, headers: { 'User-Agent' => USER_AGENT }.merge(headers), timeout: TIMEOUT)
        return response unless RETRY_ON.include?(response.code) && attempt < RETRIES

        sleep(2**attempt)
      end
    end

    def html(url)
      Nokogiri::HTML(get(url).body)
    end

    # Corre el bloque sobre cada item en paralelo (de a `threads`) y conserva el orden.
    def parallel_map(items, threads: THREADS, &)
      pool = Concurrent::FixedThreadPool.new(threads)
      futures = items.map { |item| Concurrent::Promises.future_on(pool, item, &) }
      futures.map(&:value!)
    ensure
      pool&.shutdown
    end

    # Forma común de un beneficio. weekdays vacío = no sabemos qué días aplica.
    def benefit(bank:, merchant:, description:, url:, **extra)
      text = [extra[:title], description].compact.join(' ')
      {
        bank:,
        merchant: clean(merchant),
        title: clean(extra[:title]),
        description: clean(description),
        category: clean(extra[:category]),
        discount: extra.fetch(:discount) { discount(text) },
        weekdays: extra.fetch(:weekdays) { weekdays(text) },
        cards: extra.fetch(:cards, []),
        departments: extra.fetch(:departments, []),
        valid_from: extra[:valid_from],
        valid_until: extra[:valid_until],
        logo: extra[:logo],
        url:
      }
    end

    # Mayor porcentaje mencionado ("25% y 15% menos" => 25).
    def discount(text)
      text.to_s.scan(/(\d{1,3})(?:[.,]\d+)?\s*%/).flatten.map(&:to_i).grep(1..100).max
    end

    def weekdays(text)
      text = normalize(text)
      return ALL_WEEK if text.match?(/todos los dias|cualquier dia/)

      days = day_ranges(text)
      days |= [6, 7] if text.include?('fin de semana') || text.include?('fines de semana')
      days |= text.scan(DAY_WORD).flatten.map { |word| day_number(word) }
      days.sort
    end

    def day_ranges(text)
      text.scan(/de #{DAY_WORD} a #{DAY_WORD}/).flat_map do |from, to|
        (day_number(from)..day_number(to)).to_a
      end
    end

    # "sabados" => 6, pero "miercoles" ya termina en s y es el nombre tal cual.
    def day_number(word)
      WEEKDAYS[word] || WEEKDAYS.fetch(word.delete_suffix('s'))
    end

    def normalize(text)
      # [[:space:]] incluye el espacio duro (U+00A0) que usan BBVA y otros CMS.
      I18n.transliterate(text.to_s.gsub(/[[:space:]]+/, ' ')).downcase
    end

    def clean(text)
      return if text.nil?

      ActionView::Base.full_sanitizer.sanitize(text.to_s).gsub(/[[:space:]]+/, ' ').strip.presence
    end

    def active?(from, to, today: Date.current)
      (from.blank? || Date.parse(from.to_s) <= today) && (to.blank? || Date.parse(to.to_s) >= today)
    rescue Date::Error
      true
    end

    private_class_method :day_ranges, :day_number, :clean
  end
end
