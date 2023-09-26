class Api::V1::EventsController < ApplicationController
  def antel_arena
    url = "https://www.antelarena.com.uy/events"

    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    events_data = []

    events_items = doc.css('div.eventItem')
    events_items.each do |event_item|
      events_data << {
        date: event_item.css('.info-wrapper .info .date').text.strip,
        thumbnail: event_item.css('.thumb img').attr('src').value,
        artist: event_item.css('.info-wrapper .info .h3').text.strip,
        concert: event_item.css('.info-wrapper .info .h4').text.strip,
        more_info: event_item.css('.info-wrapper .buttons a')[0]&.attr('href'),
        buy_tickets: event_item.css('.info-wrapper .buttons a.tickets')[0]&.attr('href'),
      }
    end

    render json: events_data
  end
end
