# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class Api::V1::LotteryControllerTest < ActionDispatch::IntegrationTest
  CINCO_DE_ORO_HTML = <<~HTML
    <html>
      <body>
        <div id="panel-izquierdo">
          <h2>Miércoles 4 de Marzo de 2026</h2>
          <div class="row">
            <div class="large-4 columns pozo">
              <span class="title">Pozo de Oro</span>
              <span class="title">Pozo de Plata</span>
            </div>
            <div class="large-5 columns pozo">
              <span class="monto-pozo">$ 44.441.130</span>
              <span class="monto-pozo">$ 868.121</span>
            </div>
            <div class="large-3 columns pozo">
              <span class="aciertos">(1 acierto)</span>
              <span class="aciertos">(5 aciertos)</span>
            </div>
          </div>
          <div class="row">
            <div class="large-12 columns">
              <ul class="bolillas small-block-grid-7">
                <li><img alt="1" src="/assets/bolillas/oro/1.png"></li>
                <li><img alt="4" src="/assets/bolillas/oro/4.png"></li>
                <li><img alt="7" src="/assets/bolillas/oro/7.png"></li>
                <li><img alt="28" src="/assets/bolillas/oro/28.png"></li>
                <li><img alt="32" src="/assets/bolillas/oro/32.png"></li>
                <li class="extra"><img alt="13" src="/assets/bolillas/oro/13.png"></li>
                <li class="caption">Extra</li>
              </ul>
            </div>
          </div>
          <div class="large-4 columns pozo">
            <span class="title">Pozo Revancha</span>
          </div>
          <div class="large-5 columns pozo">
            <span class="monto-pozo">$ 29.020.794</span>
          </div>
          <div class="row">
            <div class="large-12 columns">
              <ul class="bolillas small-block-grid-7">
                <li><img alt="7" src="/assets/bolillas/oro/7.png"></li>
                <li><img alt="20" src="/assets/bolillas/oro/20.png"></li>
                <li><img alt="32" src="/assets/bolillas/oro/32.png"></li>
                <li><img alt="33" src="/assets/bolillas/oro/33.png"></li>
                <li><img alt="37" src="/assets/bolillas/oro/37.png"></li>
              </ul>
            </div>
          </div>
        </div>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, "#{LotteryService::BASE_URL}/resultados/cincodeoro")
      .to_return(body: CINCO_DE_ORO_HTML, status: 200)
  end

  test "result returns success for cinco de oro" do
    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "cinco_de_oro", json["game"]
    assert_equal [1, 4, 7, 28, 32], json["numeros_primera_vuelta"]
    assert_equal 13, json["numero_extra"]
    assert_equal "$ 44.441.130", json["pozo_oro"]
    assert_equal "$ 868.121", json["pozo_plata"]
    assert_equal "$ 29.020.794", json["pozo_revancha"]
  end

  test "result returns not found for invalid game" do
    get api_v1_lottery_result_path(game: 'mega_millions')

    assert_response :not_found

    json = JSON.parse(response.body)
    assert_includes json["error"], "Juego no encontrado"
  end

  test "result includes date" do
    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    json = JSON.parse(response.body)

    assert_equal "Miércoles 4 de Marzo de 2026", json["date"]
  end

  test "result includes revancha numbers" do
    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    json = JSON.parse(response.body)

    assert_equal [7, 20, 32, 33, 37], json["numeros_revancha"]
  end

  test "games endpoint returns available games" do
    get api_v1_lottery_games_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json["games"], "cinco_de_oro"
    assert_includes json["games"], "quiniela_nocturna"
    assert_equal 5, json["games"].length
  end

  test "handles scraping failure" do
    stub_request(:get, "#{LotteryService::BASE_URL}/resultados/cincodeoro")
      .to_raise(StandardError.new("Connection failed"))

    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    assert_response :internal_server_error
  end
end
