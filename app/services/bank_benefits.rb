# Beneficios y descuentos de tarjetas de los bancos de Uruguay, con una forma común
# (ver BankBenefits::Base.benefit). Para sumar un banco: una clase con `self.fetch_all`
# en app/services/bank_benefits/ y su nombre en BANKS.
module BankBenefits
  BANKS = %w[santander itau oca bbva scotiabank].freeze

  def self.fetch(bank)
    const_get(bank.camelize).fetch_all
  end
end
