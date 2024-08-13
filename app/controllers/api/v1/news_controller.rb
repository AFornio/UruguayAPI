class Api::V1::NewsController < ApplicationController
  def headlines
    source = 'Montevideo Portal'
    url = "https://www.montevideo.com.uy/anranking.aspx?0,1798,1,0,D"

    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    titles = doc.css('h2.title')

    data = [
      {
        source: source,
        headlines: []
      }
    ]

    titles.each do |title|
      data.first[:headlines] << {
        href: title.css('a').first['href'],
        title: title.text
      }
    end

    data.first[:headlines].each do |headline|
      response = HTTParty.get(headline[:href])
      doc = Nokogiri::HTML(response.body)
      img_src = doc.css('.foto-ppal.hidden-xs img').first&.[]('src') || doc.css('#gallery-1 img').first&.[]('src') || ""
      headline[:img] = img_src
    end

    render json: data
  end
end
