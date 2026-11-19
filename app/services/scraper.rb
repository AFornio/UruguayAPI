# HTTP para scrapers: User-Agent de navegador, timeout, reintentos y paralelismo.
#
# Lo usan BankBenefits y ExchangeRates. Si un sitio sigue fallando después de los
# reintentos levanta BlockedError: mejor un error visible que una lista vacía que parece real.
module Scraper
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
               '(KHTML, like Gecko) Chrome/130 Safari/537.36'.freeze
  TIMEOUT = 30
  THREADS = 8
  RETRIES = 3
  RETRY_ON = [403, 429, 500, 502, 503, 504].freeze

  class BlockedError < StandardError; end

  module_function

  def get(url, headers: {})
    request(:get, url, headers:)
  end

  def post(url, body:, headers: {})
    request(:post, url, headers:, body:)
  end

  def html(url)
    Nokogiri::HTML(get(url).body)
  end

  # Corre el bloque sobre cada item en paralelo (de a `threads`) y conserva el orden.
  def parallel_map(items, threads: THREADS, &)
    pool = Concurrent::FixedThreadPool.new(threads)
    futures = items.map { |item| Concurrent::Promises.future_on(pool, item, &) }
    futures.map(&:value!)
  ensure
    pool&.shutdown
  end

  # Reintenta con espera creciente (BBVA corta con 403 si se le pide rápido).
  def request(method, url, headers:, **)
    (0..RETRIES).each do |attempt|
      response = HTTParty.send(method, url, headers: { 'User-Agent' => USER_AGENT }.merge(headers),
                                            timeout: TIMEOUT, **)
      return response if response.success?
      raise BlockedError, "#{url} respondió #{response.code}" if give_up?(response, attempt)

      sleep(2**attempt)
    end
  end

  def give_up?(response, attempt)
    attempt == RETRIES || !RETRY_ON.include?(response.code)
  end

  private_class_method :request, :give_up?
end
