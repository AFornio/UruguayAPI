# frozen_string_literal: true

# Servicio de cartelera de espectáculos.
#
# Scrapea cartelera.com.uy en dos modos:
#   - Billboard: resumen de la home (cine, música, videos, teatro, cable, arte).
#   - Billboard por tipo: listado completo de un tipo específico.
#
# Tipos válidos: movies, music, videos, theater, cable, art
#
# Fuente: https://www.cartelera.com.uy
class CarteleraService
  BASE_URL = 'https://cartelera.montevideo.com.uy'

  VALID_EVENT_TYPES = %w[movies music videos theater cable art].freeze

  class << self
    def fetch_billboard
      sections_data = sections.map do |section|
        { "#{section['id']}": events_data(section) }
      end

      sections_data.inject(&:merge)
    end

    def fetch_by_type(type)
      return nil unless VALID_EVENT_TYPES.include?(type)

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

    def valid_type?(type)
      VALID_EVENT_TYPES.include?(type)
    end

    private

    def extract_data(article, type)
      raw_link = article.css('.poster-container > a').first&.[]('href').to_s
      img = article.css('.poster-container > a > img').first&.[]('src')
      name = article.css('.info-holder .name').text.strip
      event_data = article.css('.info-holder .event-data li')
      raw_event_link = raw_link.start_with?('http') ? raw_link : "#{BASE_URL}/#{raw_link.sub(%r{\A/+}, '')}"
      event_link = raw_event_link.sub(%r{(?<=\w)//}, '/')
      description = nil

      case type
        when 'art'
          return {
            source: 'Cartelera',
            source_url: BASE_URL,
            title: name,
            genre: event_data.css('strong')[0]&.text&.strip,
            show: event_data.css('strong')[1]&.text&.strip,
            room: event_data.css('strong')[2]&.text&.strip,
            thumbnail: img,
            description: description,
            event_link: event_link,
          }

        when 'cable'
          return {
              source: 'Cartelera',
              source_url: BASE_URL,
              title: name,
              channel: event_data.css('strong')[0]&.text&.strip,
              schedule: event_data.css('strong')[1]&.text&.strip,
              genre: event_data.css('strong')[2]&.text&.strip,
              director: event_data.css('strong')[3]&.text&.strip,
              protagonists: event_data.css('strong')[4]&.text&.strip,
              thumbnail: img,
              description: description,
              event_link: event_link,
            }


        when 'theater'
         return {
            source: 'Cartelera',
            source_url: BASE_URL,
            title: name,
            genre: event_data.css('strong')[0]&.text&.strip,
            director: event_data.css('strong')[1]&.text&.strip,
            room: event_data.css('strong')[2]&.text&.strip,
            thumbnail: img,
            today_schedules: extract_schedules(article),
            description: description,
            event_link: event_link,
          }

      when 'videos'
        return {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: name,
          genre: event_data.css('strong')[0]&.text&.strip,
          director: event_data.css('strong')[1]&.text&.strip,
          protagonists: event_data.css('strong')[2]&.text&.strip,
          available_on: event_data.css('a').first&.[]('href'),
          thumbnail: img,
          description: description,
          event_link: event_link,
        }

      when 'music'
        return {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: name,
          cast: event_data.css('strong')[0]&.text&.strip,
          room: event_data[1]&.text&.strip,
          locations: event_data[2]&.text&.strip,
          thumbnail: img,
          description: description,
          event_link: event_link,
        }

      when 'movies'
        return {
            source: 'Cartelera',
            source_url: BASE_URL,
            title: name,
            genre: event_data.css('strong')[0]&.text&.strip,
            director: event_data.css('strong')[1]&.text&.strip,
            protagonists: event_data.css('strong')[2]&.text&.strip,
            thumbnail: img,
            today_schedules: extract_schedules(article),
            description: description,
            event_link: event_link,
          }
        end
    end

    def fetch_description(url)
      return nil unless url&.start_with?('http')

      doc = Nokogiri::HTML(HTTParty.get(url).body)
      doc.css('.container-ppal p').text.gsub(/\s+/, ' ').strip.presence
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

    def sections
      doc = Nokogiri::HTML(cartelera_response.body)
      doc.css('section')
    end

    def cartelera_response
      HTTParty.get("#{BASE_URL}/")
    end

    def events_data(section)
      section.css('.slider-holder .listado-eventos li article').map do |event|
        send("#{section['id']}_event_data", event)
      end
    end

    def cine_event_data(event)
        {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: event.css('.container .name').text.strip,
          type: event.css('.container .type').text.strip,
          trailer: event.css('.container a.trailer').first&.[]('href'),
          event_link: event.css('a').first&.[]('href'),
          thumbnail: event.css('a img').first&.[]('src')
        }
    end

    def musica_event_data(event)
        {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: event.css('.container .name').text.strip,
          featured: event.css('.container .destacado').text.strip,
          venue: event.css('.container .venue').text.strip,
          event_link: event.css('a').first&.[]('href'),
          thumbnail: event.css('a img').first&.[]('src')
        }
    end

    def videos_event_data(event)
        {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: event.css('.container .name').text.strip,
          featured: event.css('.container .destacado').text.strip,
          genre: event.css('.container p').last.text.strip,
          event_link: event.css('a').first&.[]('href'),
          thumbnail: event.css('a img').first&.[]('src')
        }
    end

    def teatro_event_data(event)
        {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: event.css('.container .name').text.strip,
          featured: event.css('.container .destacado').text.strip,
          venue: event.css('.container .venue').text.strip,
          event_link: event.css('a').first&.[]('href'),
          thumbnail: event.css('a img').first&.[]('src')
        }
    end

    def cable_event_data(event)
        {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: event.css('.container .name').text.strip,
          featured: event.css('.container .destacado').text.strip,
          channel: event.css('.container .highlight').last.text.strip,
          genre: event.css('.container p').first.text.strip,
          event_link: event.css('a').first&.[]('href'),
          thumbnail: event.css('a img').first&.[]('src')
        }
    end

    def arte_event_data(event)
        {
          source: 'Cartelera',
          source_url: BASE_URL,
          title: event.css('.container .name').text.strip,
          featured: event.css('.container .destacado').text.strip,
          genre: event.css('.container p').first.text.strip,
          artist: event.css('.container p')[1]&.text&.strip,
          venue: event.css('.container p').last.text.strip,
          event_link: event.css('a').first&.[]('href'),
          thumbnail: event.css('a img').first&.[]('src')
        }
    end
  end
end
