require "test_helper"

class Api::V1::CiControllerTest < ActionDispatch::IntegrationTest
  test "validate returns false if CI is blank" do
    get api_v1_ci_validate_path, params: { ci: '' }
    assert_response :success
    assert_equal 'false', @response.body
  end

  test "validate returns true if CI is valid" do
    get api_v1_ci_validate_path, params: { ci: '"1.111.111-1' }
    assert_response :success
    assert_equal 'true', @response.body
  end

  test "validate_digit returns error if CI is blank" do
    get api_v1_ci_validate_digit_path, params: { ci: '' }
    assert_response :unprocessable_entity
    assert_equal '{"error":"CI is required"}', @response.body
  end

  test "validate_digit returns digit if CI is valid" do
    get api_v1_ci_validate_digit_path, params: { ci: '2222222' }
    assert_response :success
    assert_equal '2', @response.body
  end

  test "random returns a random CI" do
    get api_v1_ci_random_path
    assert_response :success
    assert_match /\d{8}/, @response.body
  end
end
