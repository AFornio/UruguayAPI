# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class LotteryServiceTest < ActiveSupport::TestCase
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

  QUINIELA_JS_RESPONSE = <<~JS
    jQuery("#loading-background").css("display", "block");
    $('#panel-izquierdo').html("\t<h2>Jueves 5 de Marzo de 2026<\\/h2>\\n\t<h3>Sorteo Nocturno<\\/h3>\\n\\n\t<ul class=\\"results-column\\">\\n\t  <li><span>01.<\\/span>142<\\/li>\\n\t  <li><span>02.<\\/span>546<\\/li>\\n\t  <li><span>03.<\\/span>981<\\/li>\\n\t  <li><span>04.<\\/span>658<\\/li>\\n\t  <li><span>05.<\\/span>267<\\/li>\\n\t  <\\/ul>\\n\t<div class=\\"clear\\">&nbsp;<\\/div>\\n");
    $('#panel-error').html("");
  JS

  TOMBOLA_JS_RESPONSE = <<~JS
    jQuery("#loading-background").css("display", "block");
    $('#panel-izquierdo').html("\t<h2>Jueves 5 de Marzo de 2026<\\/h2>\\n\t<h3>Sorteo Nocturno<\\/h3>\\n\\n\t<ul class=\\"results-column\\">\\n\t  <li>13<\\/li>\\n\t  <li>15<\\/li>\\n\t  <li>16<\\/li>\\n\t  <li>17<\\/li>\\n\t  <li>20<\\/li>\\n\t  <\\/ul>\\n\t<div class=\\"clear\\">&nbsp;<\\/div>\\n");
    $('#panel-error').html("");
  JS

  # --- 5 de Oro ---

  test "cinco de oro parses numbers and extra" do
    stub_cinco_de_oro

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal [1, 4, 7, 28, 32], result[:numeros_primera_vuelta]
    assert_equal 13, result[:numero_extra]
  end

  test "cinco de oro parses pozos" do
    stub_cinco_de_oro

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal "$ 44.441.130", result[:pozo_oro]
    assert_equal "$ 868.121", result[:pozo_plata]
    assert_equal "$ 29.020.794", result[:pozo_revancha]
  end

  test "cinco de oro parses revancha numbers" do
    stub_cinco_de_oro

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal [7, 20, 32, 33, 37], result[:numeros_revancha]
  end

  test "cinco de oro parses date" do
    stub_cinco_de_oro

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal "Miércoles 4 de Marzo de 2026", result[:date]
  end

  test "cinco de oro returns game name" do
    stub_cinco_de_oro

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal "cinco_de_oro", result[:game]
  end

  test "cinco de oro returns nil on http error" do
    stub_request(:get, "#{LotteryService::BASE_URL}/resultados/cincodeoro")
      .to_return(status: 500)

    assert_nil LotteryService.fetch_result('cinco_de_oro')
  end

  # --- Quiniela ---

  test "quiniela parses numbered positions" do
    stub_quiniela('quiniela_nocturna')

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_equal 142, result[:numbers][1]
    assert_equal 546, result[:numbers][2]
    assert_equal 267, result[:numbers][5]
  end

  test "quiniela parses date and turno" do
    stub_quiniela('quiniela_nocturna')

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_equal "Jueves 5 de Marzo de 2026", result[:date]
    assert_equal "Sorteo Nocturno", result[:turno]
  end

  test "quiniela returns game name" do
    stub_quiniela('quiniela_vespertina')

    result = LotteryService.fetch_result('quiniela_vespertina')

    assert_equal "quiniela_vespertina", result[:game]
  end

  test "quiniela returns nil on http error" do
    stub_request(:post, "#{LotteryService::BASE_URL}/resultados/quiniela/renderizar_info_sorteo")
      .to_return(status: 500)

    assert_nil LotteryService.fetch_result('quiniela_nocturna')
  end

  # --- Tómbola ---

  test "tombola parses numbers as array" do
    stub_tombola('tombola_nocturna')

    result = LotteryService.fetch_result('tombola_nocturna')

    assert_equal [13, 15, 16, 17, 20], result[:numbers]
  end

  test "tombola parses date and turno" do
    stub_tombola('tombola_nocturna')

    result = LotteryService.fetch_result('tombola_nocturna')

    assert_equal "Jueves 5 de Marzo de 2026", result[:date]
    assert_equal "Sorteo Nocturno", result[:turno]
  end

  test "tombola returns game name" do
    stub_tombola('tombola_vespertina')

    result = LotteryService.fetch_result('tombola_vespertina')

    assert_equal "tombola_vespertina", result[:game]
  end

  test "tombola returns nil on http error" do
    stub_request(:post, "#{LotteryService::BASE_URL}/resultados/tombola/renderizar_info_sorteo")
      .to_return(status: 500)

    assert_nil LotteryService.fetch_result('tombola_nocturna')
  end

  # --- General ---

  test "returns nil for unknown game" do
    assert_nil LotteryService.fetch_result('mega_millions')
  end

  test "available_games returns all game keys" do
    games = LotteryService.available_games

    assert_includes games, 'cinco_de_oro'
    assert_includes games, 'quiniela_nocturna'
    assert_includes games, 'quiniela_vespertina'
    assert_includes games, 'tombola_nocturna'
    assert_includes games, 'tombola_vespertina'
    assert_equal 5, games.length
  end

  private

  def stub_cinco_de_oro
    stub_request(:get, "#{LotteryService::BASE_URL}/resultados/cincodeoro")
      .to_return(body: CINCO_DE_ORO_HTML, status: 200)
  end

  def stub_quiniela(game)
    stub_request(:post, "#{LotteryService::BASE_URL}/resultados/quiniela/renderizar_info_sorteo")
      .to_return(body: QUINIELA_JS_RESPONSE, status: 200)
  end

  def stub_tombola(game)
    stub_request(:post, "#{LotteryService::BASE_URL}/resultados/tombola/renderizar_info_sorteo")
      .to_return(body: TOMBOLA_JS_RESPONSE, status: 200)
  end
end
