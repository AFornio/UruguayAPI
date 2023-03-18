class Api::V1::GasolineController < ApplicationController

  ANCAP_GASOLINE = [
    {name: 'Super 95', url: "https://www.ancap.com.uy/1636/1/super-95.html"},
    {name: 'Premium 97', url: "https://www.ancap.com.uy/1637/1/premium-97.html"},
    {name: 'Gasoil 10-S', url: "https://www.ancap.com.uy/1641/1/gasoil-10-s.html"},
    {name: 'Gasoil 50-S', url: "https://www.ancap.com.uy/1642/1/gasoil--50-s.html"},
  ].freeze

  def index
    gasoline = {}
    threads = []
  
    ANCAP_GASOLINE.each do |ancap|
      threads << Thread.new do
        gasoline[ancap[:name]] = get_gasoline_info(ancap[:url])
      end
    end
  
    threads.each(&:join)
    render json: gasoline
  end

  def show
    gas_name = params[:name].downcase.gsub(' ', '_')
    gas = ANCAP_GASOLINE.find { |g| g[:name].downcase.gsub(' ', '_') == gas_name }

    if gas.present?
      render json: get_gasoline_info(gas[:url])
    else
      render json: { error: "Gasoline type not found" }, status: :not_found
    end
  end

  private

  def get_gasoline_info(url)
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)
    producto_data_box = doc.css('.producto-data-box')
  
    {
      max_price: producto_data_box.css('#envaseprecio')[0].text.gsub(/[\s$]/, ''),
      ancap_price: producto_data_box.css('#envaseprecio')[1].text.gsub(/[\s$]/, ''),
      currency: 'UYU'
    }
  end
end
