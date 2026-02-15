require "test_helper"
require "webmock/minitest"

class Api::V1::LotteryControllerTest < ActionDispatch::IntegrationTest
  CINCO_DE_ORO_HTML = <<~HTML
    <html>
      <body>
        <div class="resultado">
          <strong><span class="fecha">miércoles 12 de febrero 2026</span></strong>
          <div class="bolitas bolitas_uruguay">
            <span class="bolita bolita_normal">08</span>
            <span class="bolita bolita_normal">23</span>
            <span class="bolita bolita_normal">27</span>
            <span class="bolita bolita_normal">44</span>
            <span class="bolita bolita_normal">45</span>
            <span class="bolita bolita_normal bolita_extra">39</span>
          </div>
        </div>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, %r{resultadosorteo\.net/uruguay/}).to_return(body: CINCO_DE_ORO_HTML, status: 200)
  end

  test "result returns success for valid game" do
    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "cinco_de_oro", json["game"]
    assert json["numbers"].is_a?(Array)
    assert_equal 5, json["numbers"].length
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

    assert_includes json["date"], "febrero 2026"
  end

  test "result includes extra number for cinco de oro" do
    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    json = JSON.parse(response.body)

    assert_equal 39, json["extra_number"]
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
    stub_request(:get, %r{resultadosorteo\.net/uruguay/}).to_raise(StandardError.new("Connection failed"))

    get api_v1_lottery_result_path(game: 'cinco_de_oro')

    assert_response :internal_server_error
  end
end
