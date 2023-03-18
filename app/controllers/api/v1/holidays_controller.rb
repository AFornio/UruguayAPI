class Api::V1::HolidaysController < ApplicationController
  before_action :check_year

  def show
    holidays_and_observances = scrape_holidays_table("#{url}?hol=4199193")

    render json: holidays_and_observances
  end

  def official
    official = scrape_holidays_table("#{url}?hol=1")

    render json: official
  end


  def official_and_non_working
    official_and_non_working = scrape_holidays_table("#{url}?hol=9")

    render json: official_and_non_working
  end

  def holidays_and_observances
    holidays_and_observances = scrape_holidays_table("#{url}?hol=25")

    render json: holidays_and_observances
  end

  def holidays_and_observances_including_locals
    holidays_and_observances_including_locals = scrape_holidays_table("#{url}?hol=4194329")

    render json: holidays_and_observances_including_locals
  end

  private

  def check_year
    @year = params[:year]

    if !@year.present? || @year.to_i.to_s != @year
      return render json: { error: 'Invalid year' }, status: 400
    end
  end

  def url
    "https://www.timeanddate.com/holidays/uruguay/#{@year}"
  end

  def scrape_holidays_table(url)
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    holidays_data = []

    holidays_table = doc.css('#holidays-table')
    table_body = holidays_table.css('tbody')

    table_body.css('tr.showrow').each do |row|
      day_month = row.css('th').text.strip

      tds = row.css('td')
      next unless tds[0].present?
      day_of_week = tds[0].text.strip
      holiday_name = tds[1].text.strip
      holiday_type = tds[2].text.strip

      holidays_data <<  {
        day_month: day_month,
        day_of_week: day_of_week,
        holiday_name: holiday_name,
        holiday_type: holiday_type
      }
    end

    holidays_data
  end
end
