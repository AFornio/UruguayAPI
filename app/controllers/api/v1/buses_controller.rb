class Api::V1::BusesController < ApplicationController

  def options
    render json: { origins_and_destinations: BusesService.locations, companies: BusesService.companies, days: BusesService.days, shifts: BusesService.shifts }
  end

  def schedules
    unless params[:origin].present? && params[:destination].present?
      return render json: { error: 'Origin and destination are required' }
    end

    schedules, pagination = fetch_schedules

    render json: { schedules:, pagination: pagination }
  end

  def all_schedules
    unless params[:origin].present? && params[:destination].present?
      return render json: { error: 'Origin and destination are required' }
    end

    schedules, pagination = fetch_schedules(show_all: true)

    render json: { schedules:, pagination: pagination }
  end

  private

  def fetch_schedules(show_all: false)
    xxx_url = "https://www.trescruces.com.uy/horarios-destinos/"
    current_page = params[:pag] || 1
    origin = params[:origin].upcase
    destination = params[:destination].upcase

    origin_id = BusesService.get_location_id(origin)
    destination_id = BusesService.get_location_id(destination)

    query_params = "?origen=#{origin}&destino=#{destination}&origen_id=#{origin_id}&destino_id=#{destination_id}" \
                    "&empresa_id=#{params[:company_id] || 0}" \
                    "&dias_ref=#{params[:day] || 'all'}" \
                    "&turno_ref=#{params[:shift]}" \
                    "&sec=hd" \
                    "&pag=#{current_page}"

    uri = URI.parse(xxx_url + query_params)
    response = HTTParty.get(uri)
    doc = Nokogiri::HTML(response.body)

    many_results = doc.css('ul.pagination')

    if many_results.present?
      lis = many_results.css('li')[1..-2]
      max_pag = lis.last.text.strip
    end

    schedules = xxx_result_hours_list(doc)
    pagination = { showing_all: show_all }

    if show_all && !params[:pag].present? && max_pag.present?
      (2..max_pag.to_i).each do |pag|
        pag_query_param = "&pag=#{pag}"        
        uri = URI.parse(xxx_url + query_params + pag_query_param)
        response = HTTParty.get(uri)
        doc = Nokogiri::HTML(response.body)
        schedules += xxx_result_hours_list(doc)
      end
    end

    return schedules, pagination.merge({ max: max_pag || 1, current: current_page, query_param: "&pag" })
  end

  def xxx_result_hours_list(doc)
    table = doc.css('table .result-hours-list')
    schedules = []

    table.css('tr').each do |row|
      columns = row.css('td')
      schedules << {
        departure_time: columns[0].text,
        frequency: columns[1].text,
        route: columns[2].text,
        time: columns[3].text,
        distance: columns[4].text,
        company: columns[5].text.strip,
      }
    end

    return schedules
  end
end
