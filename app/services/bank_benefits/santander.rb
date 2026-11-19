# Beneficios de Santander Uruguay.
#
# La página lista todos los beneficios en el HTML (Drupal). El listado general no dice el
# rubro, así que se pide además una vez por categoría para etiquetar cada beneficio.
#
# Fuente: https://www.santander.com.uy/beneficios
module BankBenefits
  class Santander
    BASE_URL = 'https://www.santander.com.uy'.freeze
    URL = "#{BASE_URL}/beneficios".freeze
    CATEGORIES = {
      20 => 'Moda', 21 => 'Supermercados', 22 => 'Ruta Gourmet', 23 => 'Farmacia',
      24 => 'Librería', 25 => 'Deco y hogar', 26 => 'Infantil', 27 => 'Viajes y turismo',
      28 => 'Tecnología', 29 => 'Fitness', 30 => 'Autos', 134 => 'Otros', 289 => 'Heladerías'
    }.freeze
    ITEM = 'article.node--view-mode-teaser'.freeze

    class << self
      def fetch_all
        categories = category_by_id
        Scraper.html(URL).css(ITEM).uniq { |item| item['data-history-node-id'] }.map do |item|
          parse(item, categories[item['data-history-node-id']])
        end
      end

      private

      def category_by_id
        pages = Scraper.parallel_map(CATEGORIES.to_a) do |id, name|
          [name, Scraper.html("#{URL}?categoria%5B#{id}%5D=#{id}")]
        end
        pages.each_with_object({}) do |(name, doc), ids|
          doc.css(ITEM).each { |item| ids[item['data-history-node-id']] ||= name }
        end
      end

      def parse(item, category)
        logo = item.at_css('.field--name-field-company-logo img')&.[]('src')
        Base.benefit(
          bank: 'santander',
          merchant: item.at_css('.field--name-title')&.text,
          description: item.at_css('.field--name-body')&.inner_html&.gsub(%r{<br\s*/?>|</p>}, "\n"),
          category: category || 'Otros',
          logo: logo && "#{BASE_URL}#{logo}",
          url: "#{BASE_URL}#{item.at_css('a[href^="/beneficios/"]')&.[]('href')}"
        )
      end
    end
  end
end
