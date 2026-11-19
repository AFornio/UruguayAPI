require 'test_helper'
require 'webmock/minitest'

class BankBenefits::OcaTest < ActiveSupport::TestCase
  def item(uid, **attrs)
    { 'uid' => uid, 'brand' => 'TaTa', 'title_ben' => '20% de dto.', 'title_list' => '', 'description_list' => '',
      'visibility' => true, 'date_ini' => '2026-01-01', 'date_end' => '2099-01-01', 'days' => %w[0 1 2 3 4 5 6],
      'product' => %w[1 2], 'location' => (1..19).map(&:to_s), 'category' => [{ 'uid' => 'c1' }],
      'images' => { 'img_detail' => 'logo.svg' } }.merge(attrs)
  end

  setup do
    benefits = [
      item('a'),
      item('b', 'title_ben' => '20% de dto de lunes a viernes', 'location' => %w[10], 'days' => %w[4]),
      item('c', 'visibility' => false),
      item('d', 'date_end' => '2020-01-01')
    ]
    stub_request(:get, BankBenefits::Oca::CATEGORIES_URL)
      .to_return(body: { entries: [{ uid: 'c1', title: 'supermercado' }] }.to_json)
    stub_request(:get, BankBenefits::Oca::BENEFITS_URL)
      .with(headers: BankBenefits::Oca::HEADERS)
      .to_return(body: { entries: [{ benefits: }] }.to_json)
  end

  test 'solo visibles y vigentes, con tarjetas, rubro y departamentos' do
    all_week, weekdays = BankBenefits::Oca.fetch_all

    assert_equal(%w[a b], [all_week, weekdays].map { |b| b[:url][/id=(\w+)/, 1] })
    assert_equal ['OCA Visa', 'OCA Mastercard'], all_week[:cards]
    assert_equal 'Supermercado', all_week[:category]
    assert_equal [], all_week[:departments]
    assert_equal (1..7).to_a, all_week[:weekdays]
    assert_equal ['Montevideo'], weekdays[:departments]
  end

  test 'si el titulo nombra dias concretos gana sobre el CMS' do
    assert_equal [1, 2, 3, 4, 5], BankBenefits::Oca.fetch_all.second[:weekdays]
  end
end
