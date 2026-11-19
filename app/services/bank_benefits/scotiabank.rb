# Beneficios de Scotiabank Uruguay.
#
# La página carga cada beneficio con un `pushBenefit({ ... })` en un <script> inline (objeto
# JS con comillas simples, no JSON). Se leen los campos con regex y se descartan los vencidos.
#
# Fuente: https://www.scotiabank.com.uy/Personas/Tarjetas/Beneficios/default
module BankBenefits
  class Scotiabank
    URL = 'https://www.scotiabank.com.uy/Personas/Tarjetas/Beneficios/default'.freeze
    BLOCK = %r{pushBenefit\(\{(.*?)\}\);\s*</script>}m
    STRING = "'((?:\\\\.|[^'\\\\])*)'".freeze

    class << self
      def fetch_all
        Scraper.get(URL).body.scan(BLOCK).flatten.filter_map do |block|
          fields = fields(block)
          next unless Base.active?(fields['desde'], fields['hasta'])

          parse(fields, block)
        end
      end

      private

      def parse(fields, block)
        discounts = discounts(block)
        days = fields['dias'].to_s.delete_prefix('custom:')
        Base.benefit(
          bank: 'scotiabank', merchant: fields['titulo'], title: discounts.first,
          description: [*discounts, days].join("\n"),
          category: first(fields['categoria'])&.capitalize,
          weekdays: Base.weekdays(days.presence || discounts.join(' ')),
          departments: list(fields['departamento']) & Base::DEPARTMENTS,
          valid_from: fields['desde'], valid_until: fields['hasta'],
          logo: fields['logo'].presence || fields['imagen'], url: fields['link'].presence || URL
        )
      end

      # 'restaurantes, cafeteria' => ['restaurantes', 'cafeteria']
      def list(value)
        value.to_s.split(',').map(&:strip)
      end

      def first(value)
        list(value).first
      end

      # descuentos: [ { pct: '25% de ahorro', texto: 'con Platinum.' }, ... ]
      def discounts(block)
        block.scan(/pct:\s*#{STRING},\s*texto:\s*#{STRING}/o).map { |pair| pair.join(' ') }
      end

      # Campos `clave: 'valor'`. El scan consume cada string entero, así un ':' dentro de un
      # texto legal no se confunde con una clave.
      def fields(block)
        block.scan(/\b(\w+):\s*#{STRING}/o).to_h { |key, value| [key, value.gsub("\\'", "'")] }
      end
    end
  end
end
