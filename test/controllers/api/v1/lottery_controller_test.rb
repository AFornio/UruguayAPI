# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class Api::V1::LotteryControllerTest < ActionDispatch::IntegrationTest
  DNLQ_RESULTS_HTML = <<~HTML
    <html>
      <body>
        <table>
          <tr>
            <td>
              <table width="95%" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td colspan="2">
                    <table width="100%">
                      <tr>
                        <td><img src="LOTERIAS/2011/cabezal_quinielas_vespertina.png" alt="TABLA QUINIELA Y TOMBOLA VESPERTINA" />Jueves 26 de Marzo de 2026</td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td><img src="LOTERIAS/2011/logo_quiniela.png" alt="TABLA QUINIELA VESPERTINA" /></td>
                  <td><img src="LOTERIAS/2011/logo_tombola.png" alt="TABLA TOMBOLA VESPERTINA" /></td>
                </tr>
                <tr>
                  <td>
                    <table border="0" cellspacing="1" cellpadding="0">
                      <tr valign="top">
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_01.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">467</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_11.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">724</div></td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table border="0" cellpadding="0" cellspacing="5">
                      <tr>
                        <td><div align="center" class="text_azul_3">07</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><div align="center" class="text_azul_3">11</div></td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, /#{Regexp.escape(LotteryService::DNLQ_BASE_URL)}\/ver_resultados\.php/)
      .to_return(body: DNLQ_RESULTS_HTML, status: 200)
  end

  test "result returns success for quiniela vespertina" do
    get api_v1_lottery_result_path(game: 'quiniela_vespertina')

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "quiniela_vespertina", json["game"]
    assert_equal 467, json["numbers"]["1"]
    assert_equal 724, json["numbers"]["11"]
    assert_equal "Sorteo Vespertino", json["turno"]
  end

  test "result returns success for tombola vespertina" do
    get api_v1_lottery_result_path(game: 'tombola_vespertina')

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "tombola_vespertina", json["game"]
    assert_equal [7, 11], json["numbers"]
    assert_equal "Sorteo Vespertino", json["turno"]
  end

  test "result returns not found for invalid game" do
    get api_v1_lottery_result_path(game: 'mega_millions')

    assert_response :not_found

    json = JSON.parse(response.body)
    assert_includes json["error"], "Juego no encontrado"
  end

  test "result returns not found for cinco_de_oro (removed)" do
    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    assert_response :not_found
  end

  test "games endpoint returns available games" do
    get api_v1_lottery_games_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json["games"], "quiniela_nocturna"
    assert_includes json["games"], "quiniela_vespertina"
    assert_includes json["games"], "tombola_nocturna"
    assert_includes json["games"], "tombola_vespertina"
    assert_equal 4, json["games"].length
  end

  test "games endpoint does not include cinco_de_oro" do
    get api_v1_lottery_games_path

    json = JSON.parse(response.body)
    refute_includes json["games"], "cinco_de_oro"
  end

  test "handles scraping failure" do
    stub_request(:get, /#{Regexp.escape(LotteryService::DNLQ_BASE_URL)}\/ver_resultados\.php/)
      .to_raise(StandardError.new("Connection failed"))

    get api_v1_lottery_result_path(game: 'quiniela_vespertina')

    assert_response :internal_server_error
  end
end
