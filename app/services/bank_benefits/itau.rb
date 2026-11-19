# Beneficios de Itaú Uruguay.
#
# Dos fuentes:
#   - inst_camp.xml: el XML que arma https://www.itau.com.uy/inst/beneficios.html. Cada
#     beneficio aparece una vez por paquete/tarjeta que lo tiene; se agrupan por id.
#   - Landings de restaurantes y moda: listan los comercios adheridos con el % por bloque.
#     Los items del XML que apuntan a una landing se reemplazan por sus comercios.
module BankBenefits
  class Itau
    BASE_URL = 'https://www.itau.com.uy/inst'.freeze
    XML_URL = "#{BASE_URL}/aci/inst_camp.xml".freeze
    IMAGES_URL = "#{BASE_URL}/aci/images".freeze
    LANDING = %r{\Ahttps://www\.itau\.com\.uy/inst/(restaurantes|moda)\w*\.html\z}
    REGIONS = { 'tab-mvd' => 'Montevideo', 'tab-pde' => 'Maldonado' }.freeze
    # Nodos de una landing en el orden del documento: cada comercio hereda el último
    # rubro, %, condición y departamento que aparecieron antes que él (ver track_section).
    LANDING_NODES = 'section[id^="tab-"], h2, p.text-5xl, .aspect-video[title]'.freeze

    class << self
      def fetch_all
        landings, campaigns = items_by_id.partition { |group| landing?(group) }
        campaigns.filter_map { |group| parse_item(group) } + landings.flat_map { |group| parse_landing(group) }
      end

      private

      # [[nombre de la lista, item], ...] agrupados por id del beneficio.
      def items_by_id
        lists = Nokogiri::XML(Scraper.get(XML_URL).body).root.element_children
        pairs = lists.flat_map { |list| list.css('item').map { |item| [list['nombre'], item] } }
        pairs.group_by { |_, item| item['id'] }.values
      end

      def landing?(group)
        group.first.last.at_css('url')&.text&.match?(LANDING)
      end

      def parse_item(group)
        item = group.first.last
        final = item.at_css('final_item')
        return parse_link(group) if final.nil?

        title = item.at_css('titulo').text.strip
        Base.benefit(
          bank: 'itau',
          merchant: merchant_from(title),
          title:,
          description: item.at_css('descripcion')&.text.presence || final.at_css('bases')&.text,
          cards: group.map(&:first).uniq,
          logo: image(final.at_css('img_logo')&.text),
          url: "#{BASE_URL}/beneficios.html#/final_item-#{final['id']}-#{item['id']}"
        )
      end

      # Items que solo linkean a un PDF o a la web del comercio.
      def parse_link(group)
        item = group.first.last
        url = item.at_css('url')&.text
        return if url.blank?

        title = item.at_css('titulo').text.strip
        Base.benefit(bank: 'itau', merchant: merchant_from(title), title:, description: nil,
                     cards: group.map(&:first).uniq, logo: image(item.at_css('img_camp')&.text), url:)
      end

      def parse_landing(group)
        url = group.first.last.at_css('url').text
        cards = group.map(&:first).uniq
        merchants = landing_merchants(Scraper.html(url), url, cards)
        merchants.presence || [parse_link(group)].compact
      end

      def landing_merchants(doc, url, cards)
        section = {}
        doc.css(LANDING_NODES).each_with_object([]) do |node, merchants|
          if node['title']
            merchants << landing_benefit(node, section, url, cards)
          else
            track_section(node, section)
          end
        end
      end

      def landing_benefit(node, section, url, cards)
        Base.benefit(
          bank: 'itau', merchant: node['title'], title: section[:percent],
          description: [section[:percent], section[:condition]].compact.join(' '),
          category: section[:category] || (url.include?('moda') ? 'Moda' : 'Restaurantes'),
          cards:, departments: [section[:department] || section[:region]].compact,
          logo: node.at_css('img')&.[]('src'), url:
        )
      end

      # Actualiza el bloque actual (región, rubro, %, departamento) con el nodo que no es comercio.
      def track_section(node, section)
        if node.name == 'section'
          section.replace(region: REGIONS[node['id']])
        elsif node.name == 'p'
          section.merge!(percent: node.text.strip, condition: node.next_element&.text&.squish)
        elsif node['class'].to_s.include?('text-xl')
          section[:department] = node.text.strip
        else
          section.merge!(category: node.text.strip, department: nil)
        end
      end

      # "25% y 15% menos en San Roque" => "San Roque"
      def merchant_from(title)
        title[/\ben\s+(.+)\z/i, 1]&.strip || title
      end

      def image(name)
        name.present? ? "#{IMAGES_URL}/#{name}" : nil
      end
    end
  end
end
