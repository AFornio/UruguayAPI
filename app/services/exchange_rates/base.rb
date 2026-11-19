module ExchangeRates
  module Base
    class ParseError < StandardError; end

    # Un dólar fuera de este rango es un error de parseo (otra moneda, un 0, un cambio en
    # la página), no una cotización: mejor fallar que mostrarlo como "la más barata".
    PLAUSIBLE = (20..100)
    NUMBER = /(\d{1,3}[.,]\d{1,4})/
    KINDS = %w[counter online reference].freeze

    module_function

    # kind: counter (pizarra, mostrador), online (e-banking / transferencia) o reference (BCU).
    def rate(source:, name:, kind:, buy:, sell:, url:)
      raise ArgumentError, "kind inválido: #{kind}" unless KINDS.include?(kind)

      { source:, name:, kind:, currency: 'USD', buy: number(buy, source), sell: number(sell, source), url: }
    end

    # "39,40" / "39.40" / "39.4000" => 39.4
    def number(value, source)
      parsed = value.to_s.strip.tr(',', '.').to_f
      raise ParseError, "#{source}: cotización fuera de rango (#{value.inspect})" unless PLAUSIBLE.cover?(parsed)

      parsed
    end

    # Compra y venta de la fila más chica que empieza con `label` y sigue con dos números
    # ("Dólar Americano 38,90 41,40", "dolar 39.40 - 41.80", "DÓLAR 39.40 41.80").
    # `label` va sin tildes y en minúscula: el texto se normaliza antes de comparar.
    def row(doc, label, source)
      pattern = /\A(?:#{label})\s+#{NUMBER}[\s\-–]+#{NUMBER}/
      rows = doc.css('tr, div, li, p').map { |el| text_of(el) }.select { |text| text.length < 120 }
      match = rows.filter_map { |text| text.match(pattern) }.min_by { |m| m.string.length }
      raise ParseError, "#{source}: no encontré la fila #{label}" if match.nil?

      match.captures
    end

    # Une los nodos de texto con espacios (en Wix cada celda viene pegada a la otra), sin
    # tildes y en minúscula.
    def text_of(element)
      text = element.xpath('.//text()').map(&:text).join(' ').gsub(/[[:space:]]+/, ' ').strip
      I18n.transliterate(text).downcase
    end

    def today
      Time.current.in_time_zone('America/Montevideo').to_date
    end

    private_class_method :text_of
  end
end
