class Api::V1::HoroscopeController < ApplicationController

  def today
    url = 'https://www.montevideo.com.uy/horoscopo/todos'

    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    articles = doc.css('.col-sm-6.col-lg-3 article')
    horoscopes = []

    articles.each do |article|
      sign = article.css('a').attribute('name').value
      today = ""
      article.css('p').each do |p|
        today += "#{p.text} "
      end
      horoscopes << { sign: sign, horoscope: today }
    end

    render json: horoscopes
  end
end
