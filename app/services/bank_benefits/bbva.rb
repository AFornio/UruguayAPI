# Beneficios de BBVA Uruguay.
#
# Cada rubro es una página paginada ("1 de 6" => rubro.pag-2.html ...). La tarjeta del
# listado trae comercio, rubro y tarjetas/departamentos (tags); el % y la vigencia están
# solo en la página de detalle de cada comercio.
#
# Fuente: https://www.bbva.com.uy/personas/productos/tarjetas/descuentos.html
module BankBenefits
  class Bbva
    BASE_URL = 'https://www.bbva.com.uy'.freeze
    LIST_PATH = '/personas/productos/tarjetas/descuentos'.freeze
    CATEGORIES = %w[autos cuidado-personal experiencias gastronomia hogar-y-decoracion librerias-y-papelerias
                    mascotas moda mundo-infantil opticas otros tecnologia viajes vida-activa].freeze
    THREADS = 2 # con más, el firewall de BBVA responde 403 a la mitad de los pedidos
    MONTHS = %w[enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre].freeze

    class << self
      def fetch_all
        cards = Base.parallel_map(CATEGORIES, threads: THREADS) { |category| category_cards(category) }
        cards = cards.flatten.uniq { |card| card[:url] }
        Base.parallel_map(cards, threads: THREADS) { |card| with_detail(card) }
            .select { |benefit| Base.active?(nil, benefit[:valid_until]) }
      end

      private

      def category_cards(category)
        first = Base.html("#{BASE_URL}#{LIST_PATH}/#{category}.html")
        pages = first.at_css('.pagination__pages')&.text.to_s[/de\s+(\d+)/, 1].to_i
        rest = (2..pages).map { |page| Base.html("#{BASE_URL}#{LIST_PATH}/#{category}.pag-#{page}.html") }
        [first, *rest].flat_map { |doc| doc.css('article.promocard__base').map { |card| parse_card(card) } }
      end

      def parse_card(card)
        tags = card.css('.promocard__tag span').map { |tag| tag.text.strip.delete_suffix(',').strip }
        image = card.at_css('img.card__img')&.[]('src')
        {
          merchant: card.at_css('.card__title')&.text,
          title: card.at_css('.card__preheadline')&.text,
          category: card.at_css('.promocard__category')&.text&.strip,
          cards: tags.grep(/\ATarjeta/),
          departments: tags & Base::DEPARTMENTS,
          logo: image && "#{BASE_URL}#{image.split('?').first}",
          url: "#{BASE_URL}#{card.at_css('a.card__link, a[href]')['href']}"
        }
      end

      def with_detail(card)
        detail = detail(card[:url])
        # La primera lista del detalle son los descuentos; la segunda, los locales.
        discounts = detail ? detail.css('ul').first&.css('li').to_a.map(&:text) : []
        Base.benefit(bank: 'bbva', description: discounts.join("\n").presence,
                     valid_until: valid_until(detail&.text), **card)
      end

      # Si un detalle no responde, el beneficio queda con lo del listado.
      def detail(url)
        Base.html(url).at_css('.promodetail__text')
      rescue Base::BlockedError
        nil
      end

      # "Vigencia: 31 de Diciembre 2027" => "2027-12-31"
      def valid_until(text)
        day, month, year = Base.normalize(text).match(/vigencia:?\s*(\d{1,2}) de (\w+)(?: de)? (\d{4})/)&.captures
        return if day.nil? || !MONTHS.include?(month)

        Date.new(year.to_i, MONTHS.index(month) + 1, day.to_i).iso8601
      end
    end
  end
end
