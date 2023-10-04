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

  def meetups
    return render json: {error: 'Page param must be a positive number'} if !params[:page].present?
    return render json: {error: 'Page param must be a number greater than 0'} if params[:page].to_i <= 0

    page = params[:page].present? ? params[:page].to_i : 1

    url = URI("https://www.meetup.com/gql")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["authority"] = "www.meetup.com"
    request["accept"] = "*/*"
    request["accept-language"] = "es"

    after = "recSource:ml-popular-events-nearby,index:#{(page - 1) * 20}"
    after = Base64.encode64(after).chomp

    request.body = JSON.dump({
      "operationName": "categorySearch",
      "variables": {
        "first": 20,
        "lat": -32.914704,
        "lon": -55.918101,
        "topicCategoryId": nil,
        "radius": 200,
        "startDateRange": "2023-10-03T13:09:00-04:00[US/Eastern]",
        "sortField": "RELEVANCE",
        "after": after
      },
      "extensions": {
        "persistedQuery": {
          "version": 1,
          "sha256Hash": "0aceed81313ebba814c0feadeda32f404147996091b6b77209353e2183b2dabb"
        }
      }
    })

    response = https.request(request)
    body = JSON.parse(response.read_body)
    events_data = []

    body["data"]["rankedEvents"]["edges"].each do |event_item|
      events_data << {
        title:  event_item["node"]["title"],
        thumbnail: event_item["node"]["images"][0] ? event_item["node"]["images"][0]["source"] : nil,
        date_time: event_item["node"]["dateTime"],
        end_time: event_item["node"]["endTime"],
        description: event_item["node"]["description"],
        duration: event_item["node"]["duration"],
        timezone: event_item["node"]["timezone"],
        event_type: event_item["node"]["eventType"],
        event_url: event_item["node"]["eventUrl"]
      }
    end

    render json: events_data
  end
end
