# Beneficios de OCA.
#
# https://oca.uy/beneficios.html se arma en el navegador con Contentstack (CMS). Se lee la
# misma API pública con la misma clave de solo lectura que la página expone, y se aplica el
# mismo filtro que ella: visibles y vigentes hoy.
#
# Fuente: https://oca.uy/beneficios.html (src/js/get-data-beneficios.js)
module BankBenefits
  class Oca
    API_URL = 'https://cdn.contentstack.io/v3/content_types'.freeze
    HEADERS = { 'api_key' => 'blta9b90878af9436b4', 'access_token' => 'cs79086e32ff712b934208ced7' }.freeze
    BENEFITS_URL = "#{API_URL}/marketing_benefits_page/entries?environment=produccion&include[]=benefits".freeze
    CATEGORIES_URL = "#{API_URL}/marketing_benefits_category/entries?environment=produccion".freeze
    DETAIL_URL = 'https://oca.uy/beneficio-ampliado.html'.freeze
    # Códigos que usa la página (general-function-beneficios.js).
    PRODUCTS = { '1' => 'OCA Visa', '2' => 'OCA Mastercard', '3' => 'OCA Blue', '4' => 'OCA Préstamos',
                 '5' => 'OCA Seguros' }.freeze

    class << self
      def fetch_all
        categories = json(CATEGORIES_URL)['entries'].to_h { |category| [category['uid'], category['title']] }
        benefits = json(BENEFITS_URL)['entries'].first['benefits']
        benefits.select { |item| item['visibility'] && Base.active?(item['date_ini'], item['date_end']) }
                .map { |item| parse(item, categories) }
      end

      private

      def json(url)
        JSON.parse(Base.get(url, headers: HEADERS).body)
      end

      def parse(item, categories)
        Base.benefit(
          bank: 'oca',
          merchant: item['brand'],
          title: item['title_ben'].presence || item['title_list'],
          description: item['description_list'],
          category: categories[item.dig('category', 0, 'uid')]&.capitalize,
          weekdays: weekdays(item),
          cards: item['product'].to_a.filter_map { |code| PRODUCTS[code] },
          departments: departments(item['location'].to_a),
          valid_from: item['date_ini'], valid_until: item['date_end'],
          logo: item.dig('images', 'img_detail'),
          url: "#{DETAIL_URL}?id=#{item['uid']}"
        )
      end

      # El CMS a veces dice "todos los días" y el título "de lunes a viernes": si el texto
      # nombra días concretos, gana el texto. OCA numera 0 = lunes.
      def weekdays(item)
        from_text = Base.weekdays([item['title_ben'], item['title_list'], item['description_list']].join(' '))
        return from_text if from_text.any? && from_text != Base::ALL_WEEK

        item['days'].to_a.map { |day| day.to_i + 1 }.sort
      end

      # Departamentos del 1 al 19 en orden alfabético (el beneficio "Interior" trae todos
      # menos el 10, Montevideo).
      def departments(codes)
        return [] if codes.size >= Base::DEPARTMENTS.size

        codes.filter_map { |code| Base::DEPARTMENTS[code.to_i - 1] }
      end
    end
  end
end
