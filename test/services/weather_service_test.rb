require "test_helper"
require "webmock/minitest"

class WeatherServiceTest < ActiveSupport::TestCase
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
          {
            orden: 1, subgrupo: "Mañana", estadoTiempo: "11",
            descripcion: "Nuboso y cubierto.",
            evolucion: "Precipitaciones y tormentas.",
            descripcionExtra: "Mejoras temporarias.",
            vientos: "NE y E 10-30 km/h"
          },
          {
            orden: 2, subgrupo: "Tarde/Noche", estadoTiempo: "13",
            descripcion: "Cubierto a nuboso.",
            evolucion: "",
            descripcionExtra: "Neblinas.",
            vientos: "Sector E 10-30 km/h"
          }
        ]
      },
      {
        zonaId: 88, zonaCorta: "M", zonaLarga: "Área Metropolitana",
        diaMasN: 1, tempMin: 20, tempMax: 30,
        grupo: "Lunes 16", grupoCorto: "Lun 16",
        estadoTiempo: "13", probLluvia: "Baja"
      },
      {
        zonaId: 66, zonaCorta: "NW", zonaLarga: "Noroeste",
        diaMasN: 0, tempMin: 19, tempMax: 34,
        grupo: "Domingo 15", grupoCorto: "Dom 15",
        estadoTiempo: "11", probLluvia: "Alta"
      }
    ]
  }.to_json

  CURRENT_JSON = {
    estaciones: [
      { id: 211, nombre: "Prado", displayNamePublic: "Prado",
        latitud: -34.8607, longitud: -56.2079 },
      { id: 39, nombre: "Carrasco", displayNamePublic: "Carrasco",
        latitud: -34.8329, longitud: -56.0129 },
      { id: 100, nombre: "Salto", displayNamePublic: "Salto",
        latitud: -31.3833, longitud: -57.9667 }
    ],
    variables: [
      { idStr: "TempAire" },
      { idStr: "HumRelativa" },
      { idStr: "DirViento" },
      { idStr: "IntViento" },
      { idStr: "PresAtmMar" },
      { idStr: "precipHoraria" }
    ],
    fechas: ["2026-02-15T16:00:00.000-03:00", "2026-02-15T17:00:00.000-03:00"],
    observaciones: [
      { datos: [[22.0, 23.5], [21.0, 22.0], [30.0, 31.0]] },
      { datos: [[75, 80], [70, 78], [60, 65]] },
      { datos: [[180, 200], [150, 160], [90, 100]] },
      { datos: [[10, 12], [8, 10], [15, 18]] },
      { datos: [[1015.0, 1014.5], [1016.0, 1015.0], [1012.0, 1011.0]] },
      { datos: [[0.0, 0.2], [0.0, 0.0], [0.0, 1.5]] }
    ]
  }.to_json

  ALERTS_CHECK_FALSE = { has_avisos: false }.to_json
  ALERTS_CHECK_TRUE = { has_avisos: true }.to_json
  ALERTS_DETAIL = { fenomeno: "Tormentas fuertes", nivel: "Naranja" }.to_json

  setup do
    stub_request(:get, WeatherService::FORECAST_URL).to_return(body: FORECAST_JSON, status: 200)
    stub_request(:get, WeatherService::CURRENT_URL).to_return(body: CURRENT_JSON, status: 200)
    stub_request(:get, WeatherService::ALERTS_URL).to_return(body: ALERTS_CHECK_FALSE, status: 200)
  end

  # --- Forecast ---

  test "forecast returns data for valid department" do
    result = WeatherService.fetch_forecast('montevideo')

    assert_equal "montevideo", result[:department]
    assert_equal "Área Metropolitana", result[:zone]
    assert_equal "Fabiana Rozza", result[:forecaster]
  end

  test "forecast returns only items for the department zone" do
    result = WeatherService.fetch_forecast('montevideo')

    assert_equal 2, result[:forecast].length
    assert_equal "Domingo 15", result[:forecast][0][:day]
    assert_equal "Lunes 16", result[:forecast][1][:day]
  end

  test "forecast includes temperature" do
    result = WeatherService.fetch_forecast('montevideo')
    day = result[:forecast][0]

    assert_equal 18, day[:temp_min]
    assert_equal 28, day[:temp_max]
  end

  test "forecast includes weather condition text" do
    result = WeatherService.fetch_forecast('montevideo')
    day = result[:forecast][0]

    assert_equal "Nublado", day[:weather_condition]
  end

  test "forecast includes rain probability" do
    result = WeatherService.fetch_forecast('montevideo')

    assert_equal "Media", result[:forecast][0][:rain_probability]
  end

  test "forecast includes periods with details" do
    result = WeatherService.fetch_forecast('montevideo')
    periods = result[:forecast][0][:periods]

    assert_equal 2, periods.length
    assert_equal "Mañana", periods[0][:period]
    assert_equal "Tarde/Noche", periods[1][:period]
    assert_includes periods[0][:description], "Nuboso"
  end

  test "forecast returns nil for unknown department" do
    result = WeatherService.fetch_forecast('narnia')

    assert_nil result
  end

  test "forecast works for different departments" do
    result = WeatherService.fetch_forecast('salto')

    assert_equal "salto", result[:department]
    assert_equal "Noroeste", result[:zone]
  end

  # --- Current conditions ---

  test "current returns stations for department" do
    result = WeatherService.fetch_current('montevideo')

    assert_equal "montevideo", result[:department]
    assert_equal 2, result[:stations].length
  end

  test "current stations have name and coordinates" do
    result = WeatherService.fetch_current('montevideo')
    station = result[:stations].first

    assert_equal "Prado", station[:name]
    assert_in_delta(-34.8607, station[:latitude], 0.001)
    assert_in_delta(-56.2079, station[:longitude], 0.001)
  end

  test "current stations have readings" do
    result = WeatherService.fetch_current('montevideo')
    readings = result[:stations].first[:readings]

    assert_in_delta 23.5, readings[:temperature], 0.1
    assert_equal 80, readings[:humidity]
  end

  test "current converts wind from knots to kmh" do
    result = WeatherService.fetch_current('montevideo')
    readings = result[:stations].first[:readings]

    assert readings[:wind_speed_kmh] > 0
  end

  test "current returns nil for unknown department" do
    result = WeatherService.fetch_current('narnia')

    assert_nil result
  end

  test "current includes timestamp" do
    result = WeatherService.fetch_current('montevideo')

    assert_includes result[:timestamp], "2026-02-15"
  end

  # --- Alerts ---

  test "alerts returns no alerts when none active" do
    result = WeatherService.fetch_alerts

    assert_equal false, result[:has_alerts]
    assert_empty result[:alerts]
  end

  test "alerts returns details when active" do
    stub_request(:get, WeatherService::ALERTS_URL).to_return(body: ALERTS_CHECK_TRUE, status: 200)
    stub_request(:get, WeatherService::ALERTS_DETAIL_URL).to_return(body: ALERTS_DETAIL, status: 200)

    result = WeatherService.fetch_alerts

    assert result[:has_alerts]
  end

  # --- Departments list ---

  test "departments returns sorted list" do
    deps = WeatherService.departments

    assert_includes deps, 'montevideo'
    assert_includes deps, 'salto'
    assert_equal deps, deps.sort
  end
end
