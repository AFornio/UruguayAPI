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

  BASE_URL = 'https://www.cartelera.com.uy'

  def billboard
    render json: billboard_data
  end

  def billboard_event
    event_type = params[:event_type]

    return render json: { error: 'Invalid event type' }, status: :not_found unless valid_event_types.include?(event_type)
    return render json: scrape_data(event_type)
  end

  def scrape_data(type)
    url = build_url(type)
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)
    articles = doc.css('ul.listado-eventos li article')
    data = []

    articles.each do |article|
      data << extract_data(article, type)
    end

    data
  end

  private

  def extract_data(article, type)
    img = article.css('.poster-container > a > img').first&.[]('src')
    name = article.css('.info-holder .name').text.strip
    event_data = article.css('.info-holder .event-data li')

    case type
      when 'art'
        return {
          "#{name}": {
            genre: event_data.css('strong')[0]&.text&.strip,
            show: event_data.css('strong')[1]&.text&.strip,
            room: event_data.css('strong')[2]&.text&.strip,
            img: img,
          }
        }

      when 'cable'
        return {
          "#{name}": {
            channel: event_data.css('strong')[0]&.text&.strip,
            shcedule: event_data.css('strong')[1]&.text&.strip,
            genre: event_data.css('strong')[2]&.text&.strip,
            director: event_data.css('strong')[3]&.text&.strip,
            protagonists: event_data.css('strong')[4]&.text&.strip,
            img: img,
          }
        }

      when 'theater'
      theater_data = {
        "#{name}": {
          genre: event_data.css('strong')[0]&.text&.strip,
          director: event_data.css('strong')[1]&.text&.strip,
          room: event_data.css('strong')[2]&.text&.strip,
          img: img,
          today_schedules: extract_schedules(article)
        }
      }
      return theater_data

    when 'videos'
      director = event_data.css('strong')[1]&.text&.strip
      protagonists = event_data.css('strong')[2]&.text&.strip
      available_on = event_data.css('a').first&.[]('href')

      return {
        "#{name}": {
          genre: event_data.css('strong')[0]&.text&.strip,
          director: event_data.css('strong')[1]&.text&.strip,
          protagonists: event_data.css('strong')[2]&.text&.strip,
          available_on: event_data.css('a').first&.[]('href'),
          img: data[:img]
        }
      }

    when 'music'
      return {
        "#{name}": {
          cast: event_data.css('strong')[0]&.text&.strip,
          room: data[:event_data][1]&.text&.strip,
          locations: data[:event_data][2]&.text&.strip,
          img: img,
        }
      }

    when 'movies'
      return {
        "#{name}": {
          genre: event_data.css('strong')[0]&.text&.strip,
          director: event_data.css('strong')[1]&.text&.strip,
          protagonists: event_data.css('strong')[2]&.text&.strip,
          img: img,
          today_schedules: extract_schedules(article)
        }
      }
      end
  end

  def extract_schedules(article)
    schedules_list = article.css('.horarios-container .salas > li')
    return [] if schedules_list.empty?

    schedules = []
    schedules_list.each do |schedule_item|
      place = schedule_item.css('.heading.small').text.strip
      shcedule_data = {
        "#{place}": {
          hours: [],
          language: [],
        }
      }

      schedule_item.css('ul.lista-horarios > li').each do |schedule|
        shcedule_data[:"#{place}"][:language] << schedule.css('.subheading').text.strip
        shcedule_data[:"#{place}"][:hours] << schedule.css('ul > li.hour').text.strip
      end

      schedules << shcedule_data
    end

    return schedules
  end


  def valid_event_types
    %w[movies music videos theater cable art]
  end

  def build_url(type)
    case type
      when 'art'
        "#{BASE_URL}/avercarteleraarte.aspx?123"
      when 'cable'
        "#{BASE_URL}/apeliculafuncionescable.aspx?,FILM,0,0,109"
      when 'theater'
        "#{BASE_URL}/apeliculafunciones.aspx?,,PELICULAS,OBRA,0,111"
      when 'videos'
        "#{BASE_URL}/avercarteleraondemand.aspx?121"
      when 'music'
        "#{BASE_URL}/aporfechas.aspx?6,112,0,2"
      when 'movies'
        "#{BASE_URL}/apeliculafunciones.aspx?,,PELICULAS,FILM,0,108"
      end
  end

  def billboard_data
    sections_data = sections.map do |section|
      { "#{section['id']}": events_data(section) }
    end

    sections_data.inject(&:merge)
  end

  def sections
    doc = Nokogiri::HTML(cartelera_response.body)
    doc.css('section')
  end

  def cartelera_response
    HTTParty.get("https://www.cartelera.com.uy/")
  end

  def events_data(section)
    section.css('.slider-holder .listado-eventos li article').map do |event|
      send("#{section['id']}_event_data", event)
    end
  end

  def cine_event_data(event)
    {
      "#{event.css('.container .name').text.strip}": {
        type: event.css('.container .type').text.strip,
        trailer: event.css('.container a.trailer').first&.[]('href'),
        info: event.css('a').first&.[]('href'),
        img: event.css('a img').first&.[]('src')
      }
    }
  end

  def musica_event_data(event)
    {
      "#{event.css('.container .name').text.strip}": {
        featured: event.css('.container .destacado').text.strip,
        venue: event.css('.container .venue').text.strip,
        info: event.css('a').first&.[]('href'),
        img: event.css('a img').first&.[]('src')
      }
    }
  end

  def videos_event_data(event)
    {
      "#{event.css('.container .name').text.strip}": {
        featured: event.css('.container .destacado').text.strip,
        genre: event.css('.container p').last.text.strip,
        info: event.css('a').first&.[]('href'),
        img: event.css('a img').first&.[]('src')
      }
    }
  end

  def teatro_event_data(event)
    {
      "#{event.css('.container .name').text.strip}": {
        featured: event.css('.container .destacado').text.strip,
        venue: event.css('.container .venue').text.strip,
        info: event.css('a').first&.[]('href'),
        img: event.css('a img').first&.[]('src')
      }
    }
  end

  def cable_event_data(event)
    {
      "#{event.css('.container .name').text.strip}": {
        featured: event.css('.container .destacado').text.strip,
        channel: event.css('.container .highlight').last.text.strip,
        genre: event.css('.container p').first.text.strip,
        info: event.css('a').first&.[]('href'),
        img: event.css('a img').first&.[]('src')
      }
    }
  end

  def arte_event_data(event)
    {
      "#{event.css('.container .name').text.strip}": {
        featured: event.css('.container .destacado').text.strip,
        genre: event.css('.container p').first.text.strip,
        artist: event.css('.container p')[1]&.text&.strip,
        venue: event.css('.container p').last.text.strip,
        info: event.css('a').first&.[]('href'),
        img: event.css('a img').first&.[]('src')
      }
    }
  end
end
