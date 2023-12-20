class Api::V1::HolidaysController < ApplicationController

  def index
    url = "https://www.descubrimontevideo.uy/dias-festivos"
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    holidays = []

    doc.css('._none.block.block-layout-builder.block-field-blocknodepagebody > .content ul li').each do |li|
      holidays << li.text
    end 

    render json: holidays
  end
end
