# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class LotteryServiceTest < ActiveSupport::TestCase
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
                      <tr valign="top">
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_02.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">269</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_12.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">707</div></td>
                      </tr>
                      <tr valign="top">
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_03.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">184</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_13.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">141</div></td>
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
                      <tr>
                        <td><div align="center" class="text_azul_3">19</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><div align="center" class="text_azul_3">24</div></td>
                      </tr>
                      <tr>
                        <td><div align="center" class="text_azul_3">40</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><div align="center" class="text_azul_3">41</div></td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td>
              <table width="95%" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td colspan="2">
                    <table width="100%">
                      <tr>
                        <td><img src="LOTERIAS/2011/cabezal_quinielas_nocturno.png" alt="TABLA QUINIELA Y TOMBOLA NOCTURNO" />Jueves 26 de Marzo de 2026</td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td><img src="LOTERIAS/2011/logo_quiniela.png" alt="TABLA QUINIELA NOCTURNO" /></td>
                  <td><img src="LOTERIAS/2011/logo_tombola.png" alt="TABLA TOMBOLA NOCTURNO" /></td>
                </tr>
                <tr>
                  <td>
                    <table border="0" cellspacing="1" cellpadding="0">
                      <tr valign="top">
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_01.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">866</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_11.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">545</div></td>
                      </tr>
                      <tr valign="top">
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_02.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">768</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><img src="LOTERIAS/2011/numeros_tablas/l_12.gif" alt="Número del Premio" /></td>
                        <td>&nbsp;</td>
                        <td><div align="center" class="text_azul_3">095</div></td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table border="0" cellpadding="0" cellspacing="5">
                      <tr>
                        <td><div align="center" class="text_azul_3">18</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><div align="center" class="text_azul_3">24</div></td>
                      </tr>
                      <tr>
                        <td><div align="center" class="text_azul_3">32</div></td>
                        <td><img src="LOTERIAS/2011/gif_2.gif" /></td>
                        <td><div align="center" class="text_azul_3">39</div></td>
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

  # --- Quiniela (DNLQ) ---

  test "quiniela vespertina parses numbered positions" do
    stub_dnlq

    result = LotteryService.fetch_result('quiniela_vespertina')

    assert_equal 467, result[:numbers][1]
    assert_equal 269, result[:numbers][2]
    assert_equal 184, result[:numbers][3]
    assert_equal 724, result[:numbers][11]
  end

  test "quiniela nocturna parses numbered positions" do
    stub_dnlq

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_equal 866, result[:numbers][1]
    assert_equal 768, result[:numbers][2]
    assert_equal 545, result[:numbers][11]
    assert_equal 95, result[:numbers][12]
  end

  test "quiniela parses date and turno" do
    stub_dnlq

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_equal "Jueves 26 de Marzo de 2026", result[:date]
    assert_equal "Sorteo Nocturno", result[:turno]
  end

  test "quiniela vespertina returns correct turno" do
    stub_dnlq

    result = LotteryService.fetch_result('quiniela_vespertina')

    assert_equal "Sorteo Vespertino", result[:turno]
  end

  test "quiniela returns game name" do
    stub_dnlq

    result = LotteryService.fetch_result('quiniela_vespertina')

    assert_equal "quiniela_vespertina", result[:game]
  end

  test "quiniela returns nil on http error" do
    stub_dnlq_error

    assert_nil LotteryService.fetch_result('quiniela_nocturna')
  end

  # --- Tómbola (DNLQ) ---

  test "tombola vespertina parses numbers as array" do
    stub_dnlq

    result = LotteryService.fetch_result('tombola_vespertina')

    assert_equal [7, 11, 19, 24, 40, 41], result[:numbers]
  end

  test "tombola nocturna parses numbers as array" do
    stub_dnlq

    result = LotteryService.fetch_result('tombola_nocturna')

    assert_equal [18, 24, 32, 39], result[:numbers]
  end

  test "tombola parses date and turno" do
    stub_dnlq

    result = LotteryService.fetch_result('tombola_nocturna')

    assert_equal "Jueves 26 de Marzo de 2026", result[:date]
    assert_equal "Sorteo Nocturno", result[:turno]
  end

  test "tombola returns game name" do
    stub_dnlq

    result = LotteryService.fetch_result('tombola_vespertina')

    assert_equal "tombola_vespertina", result[:game]
  end

  test "tombola returns nil on http error" do
    stub_dnlq_error

    assert_nil LotteryService.fetch_result('tombola_nocturna')
  end

  # --- General ---

  test "returns nil for unknown game" do
    assert_nil LotteryService.fetch_result('mega_millions')
  end

  test "returns nil for cinco_de_oro (removed)" do
    assert_nil LotteryService.fetch_result('cinco_de_oro')
  end

  test "available_games returns all game keys" do
    games = LotteryService.available_games

    assert_includes games, 'quiniela_nocturna'
    assert_includes games, 'quiniela_vespertina'
    assert_includes games, 'tombola_nocturna'
    assert_includes games, 'tombola_vespertina'
    assert_equal 4, games.length
  end

  test "available_games does not include cinco_de_oro" do
    refute_includes LotteryService.available_games, 'cinco_de_oro'
  end

  private

  def stub_dnlq
    stub_request(:get, /#{Regexp.escape(LotteryService::DNLQ_BASE_URL)}\/ver_resultados\.php/)
      .to_return(body: DNLQ_RESULTS_HTML, status: 200)
  end

  def stub_dnlq_error
    stub_request(:get, /#{Regexp.escape(LotteryService::DNLQ_BASE_URL)}\/ver_resultados\.php/)
      .to_return(status: 500)
  end
end
