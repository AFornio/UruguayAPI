require "test_helper"
require "webmock/minitest"

class Api::V1::WeatherControllerTest < ActionDispatch::IntegrationTest
  FORECAST_JSON = {
    fechaPublicacion: "2026-02-15 18:00",
    inicioPronostico: "2026-02-15",
    activo: "true",
    pronosticador: "Fabiana Rozza",
    items: [
      {
        zonaId: 88, zonaCorta: "M", zonaLarga: "Área Metropolitana",
        diaMasN: 0, tempMin: 18, tempMax: 28,
        grupo: "Domingo 15", grupoCorto: "Dom 15",
        estadoTiempo: "4", probLluvia: "Media",
        subgrupos: [
          { orden: 1, subgrupo: "Mañana", estadoTiempo: "11",
            descripcion: "Nuboso.", evolucion: "Tormentas.",
            descripcionExtra: "", vientos: "NE 10-30 km/h" }
        ]
      }
    ]
  }.to_json

  CURRENT_JSON = {
    estaciones: [
      { id: 211, nombre: "Prado", displayNamePublic: "Prado",
        latitud: -34.86, longitud: -56.21 }
    ],
    variables: [{ idStr: "TempAire" }, { idStr: "HumRelativa" }],
    fechas: ["2026-02-15T17:00:00.000-03:00"],
    observaciones: [
      { datos: [[23.5]] },
      { datos: [[80]] }
    ]
  }.to_json

  ALERTS_JSON = { has_avisos: false }.to_json

  setup do
    stub_request(:get, WeatherService::FORECAST_URL).to_return(body: FORECAST_JSON, status: 200)
    stub_request(:get, WeatherService::CURRENT_URL).to_return(body: CURRENT_JSON, status: 200)
    stub_request(:get, WeatherService::ALERTS_URL).to_return(body: ALERTS_JSON, status: 200)
  end

  # --- Forecast ---

  test "forecast returns success for valid department" do
    get api_v1_weather_forecast_path, params: { department: 'montevideo' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "montevideo", json["department"]
    assert_equal "Área Metropolitana", json["zone"]
    assert json["forecast"].is_a?(Array)
  end

  test "forecast returns error when department missing" do
    get api_v1_weather_forecast_path

    assert_response :unprocessable_entity
  end

  test "forecast returns not found for invalid department" do
    get api_v1_weather_forecast_path, params: { department: 'narnia' }

    assert_response :not_found
  end

  test "forecast is case insensitive" do
    get api_v1_weather_forecast_path, params: { department: 'Montevideo' }

    assert_response :success
  end

  test "forecast includes temperature data" do
    get api_v1_weather_forecast_path, params: { department: 'montevideo' }

    json = JSON.parse(response.body)
    day = json["forecast"].first

    assert_equal 18, day["temp_min"]
    assert_equal 28, day["temp_max"]
  end

  # --- Current ---

  test "current returns success for valid department" do
    get api_v1_weather_current_path, params: { department: 'montevideo' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "montevideo", json["department"]
    assert json["stations"].is_a?(Array)
  end

  test "current returns error when department missing" do
    get api_v1_weather_current_path

    assert_response :unprocessable_entity
  end

  test "current returns not found for invalid department" do
    get api_v1_weather_current_path, params: { department: 'narnia' }

    assert_response :not_found
  end

  test "current includes station readings" do
    get api_v1_weather_current_path, params: { department: 'montevideo' }

    json = JSON.parse(response.body)
    station = json["stations"].first

    assert_equal "Prado", station["name"]
    assert_in_delta 23.5, station["readings"]["temperature"], 0.1
  end

  # --- Alerts ---

  test "alerts returns success" do
    get api_v1_weather_alerts_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal false, json["has_alerts"]
  end

  # --- Error handling ---

  test "forecast handles scraping failure" do
    stub_request(:get, WeatherService::FORECAST_URL).to_raise(StandardError.new("Connection failed"))

    get api_v1_weather_forecast_path, params: { department: 'montevideo' }

    assert_response :internal_server_error

    json = JSON.parse(response.body)
    assert_includes json, "error"
  end
end
