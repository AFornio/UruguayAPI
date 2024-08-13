class Api::V1::BusesController < ApplicationController
  def schedules
    # Empresa;Origen;Depto.Origen;Destino;Depto.Destino;H.Salida;H.Llegada;Recorrido;Dias;Lugar;Depto.Lugar;Hora;F.Inicio;F.Fin;Id.Turno
    url = "https://catalogodatos.gub.uy/dataset/1d50ccf7-121d-48a7-951e-28a02858d24e/resource/88839e85-a573-40e1-9bc2-72cd0fb4d8be/download/horarios_largadistancia_dnt.csv"
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    csv_data = response.body

    schedules = []
    CSV.parse(csv_data, headers: true) do |row|
      row_string = row.to_s
      split_row = row_string.split(';')
      schedules << {
        company: split_row[0].force_encoding("ISO-8859-1").encode("UTF-8"),
        origin: split_row[1].force_encoding("ISO-8859-1").encode("UTF-8"),
        origin_department: split_row[2].force_encoding("ISO-8859-1").encode("UTF-8"),
        destination: split_row[3].force_encoding("ISO-8859-1").encode("UTF-8"),
        destination_department: split_row[4].force_encoding("ISO-8859-1").encode("UTF-8"),
        departure_time: split_row[5].force_encoding("ISO-8859-1").encode("UTF-8"),
        arrival_time: split_row[6].force_encoding("ISO-8859-1").encode("UTF-8"),
        route: split_row[7].force_encoding("ISO-8859-1").encode("UTF-8"),
        days: split_row[8].force_encoding("ISO-8859-1").encode("UTF-8"),
        place: split_row[9].force_encoding("ISO-8859-1").encode("UTF-8"),
        place_department: split_row[10].force_encoding("ISO-8859-1").encode("UTF-8"),
        hour: split_row[11].force_encoding("ISO-8859-1").encode("UTF-8"),
        start_date: split_row[12].force_encoding("ISO-8859-1").encode("UTF-8"),
        end_date: split_row[13].force_encoding("ISO-8859-1").encode("UTF-8"),
        shift_id: split_row[14].force_encoding("ISO-8859-1").encode("UTF-8"),
      }
    end

    render json: { schedules: schedules }
  end
end
