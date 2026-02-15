require "test_helper"
require "webmock/minitest"

class LotteryServiceTest < ActiveSupport::TestCase
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

  QUINIELA_HTML = <<~HTML
    <html>
      <body>
        <strong>quiniela nocturna <span class="fecha">sábado 14 de febrero 2026</span></strong>
        <div class="quiniela_numero">
          <ul>
            <li>01: <span>867</span></li>
            <li>02: <span>816</span></li>
            <li>03: <span>127</span></li>
            <li>04: <span>453</span></li>
            <li>05: <span>912</span></li>
          </ul>
          <ul>
            <li>06: <span>345</span></li>
            <li>07: <span>678</span></li>
            <li>08: <span>901</span></li>
            <li>09: <span>234</span></li>
            <li>10: <span>567</span></li>
          </ul>
        </div>
      </body>
    </html>
  HTML

  TOMBOLA_HTML = <<~HTML
    <html>
      <body>
        <strong>tómbola nocturna <span class="fecha">sábado 14 de febrero 2026</span></strong>
        <div class="tombola_numero">
          <ul>
            <li>01: <span>42</span></li>
            <li>02: <span>15</span></li>
            <li>03: <span>78</span></li>
            <li>04: <span>93</span></li>
            <li>05: <span>61</span></li>
          </ul>
        </div>
      </body>
    </html>
  HTML

  # --- 5 de Oro ---

  test "cinco de oro parses 5 numbers and extra" do
    stub_request(:get, "#{LotteryService::BASE_URL}/5-de-oro/")
      .to_return(body: CINCO_DE_ORO_HTML, status: 200)

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal [8, 23, 27, 44, 45], result[:numbers]
    assert_equal 39, result[:extra_number]
  end

  test "cinco de oro parses date" do
    stub_request(:get, "#{LotteryService::BASE_URL}/5-de-oro/")
      .to_return(body: CINCO_DE_ORO_HTML, status: 200)

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_includes result[:date], "febrero 2026"
  end

  test "cinco de oro returns game name" do
    stub_request(:get, "#{LotteryService::BASE_URL}/5-de-oro/")
      .to_return(body: CINCO_DE_ORO_HTML, status: 200)

    result = LotteryService.fetch_result('cinco_de_oro')

    assert_equal "cinco_de_oro", result[:game]
  end

  # --- Quiniela ---

  test "quiniela parses numbered positions" do
    stub_request(:get, "#{LotteryService::BASE_URL}/quiniela-nocturna/")
      .to_return(body: QUINIELA_HTML, status: 200)

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_equal 867, result[:numbers][1]
    assert_equal 816, result[:numbers][2]
    assert_equal 567, result[:numbers][10]
  end

  test "quiniela parses all 10 positions" do
    stub_request(:get, "#{LotteryService::BASE_URL}/quiniela-nocturna/")
      .to_return(body: QUINIELA_HTML, status: 200)

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_equal 10, result[:numbers].length
  end

  test "quiniela parses date" do
    stub_request(:get, "#{LotteryService::BASE_URL}/quiniela-nocturna/")
      .to_return(body: QUINIELA_HTML, status: 200)

    result = LotteryService.fetch_result('quiniela_nocturna')

    assert_includes result[:date], "febrero 2026"
  end

  # --- Tómbola ---

  test "tombola parses numbered positions" do
    stub_request(:get, "#{LotteryService::BASE_URL}/tombola-nocturna/")
      .to_return(body: TOMBOLA_HTML, status: 200)

    result = LotteryService.fetch_result('tombola_nocturna')

    assert_equal 42, result[:numbers][1]
    assert_equal 15, result[:numbers][2]
  end

  test "tombola returns game name" do
    stub_request(:get, "#{LotteryService::BASE_URL}/tombola-nocturna/")
      .to_return(body: TOMBOLA_HTML, status: 200)

    result = LotteryService.fetch_result('tombola_nocturna')

    assert_equal "tombola_nocturna", result[:game]
  end

  # --- General ---

  test "returns nil for unknown game" do
    result = LotteryService.fetch_result('mega_millions')

    assert_nil result
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
end
