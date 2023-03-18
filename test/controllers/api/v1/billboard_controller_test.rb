require "test_helper"

class Api::V1::BillboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_billboard_index_url
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal response_data.keys.sort, ["arte", "cable", "cine", "musica", "teatro", "videos"].sort

    response_data.each do |key, value|
      assert_instance_of Array, value
      value.each do |item|
        assert_instance_of Hash, item
      end
    end
  end

  test "should return event type data" do
    get api_v1_billboard_path(:art)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array)

    get api_v1_billboard_path(:cable)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array)

    get api_v1_billboard_path(:movies)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array)

    get api_v1_billboard_path(:music)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array)

    get api_v1_billboard_path(:theater)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array)

    get api_v1_billboard_path(:videos)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array)
  end

  test "should return error for invalid event type" do
    get api_v1_billboard_path(:invalid_event_type)
    assert_response :not_found
  end
end
