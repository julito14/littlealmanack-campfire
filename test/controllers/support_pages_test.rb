require "test_helper"

class SupportPagesTest < ActionDispatch::IntegrationTest
  test "members read the starting text: the support email and the tips" do
    sign_in :kevin
    get support_page_url

    assert_response :success
    assert_select "h1", "Support & tips"
    assert_select ".lexxy-content a[href='mailto:julio@pickingnuggets.com']"
    assert_select ".lexxy-content h3", text: /home screen/
    assert_select "a[href=?]", edit_support_page_path, count: 0
  end

  test "members can't edit it" do
    sign_in :kevin

    get edit_support_page_url
    assert_response :forbidden

    patch support_page_url, params: { account: { support_text: "<p>Hijacked</p>" } }
    assert_response :forbidden
    assert_predicate accounts(:signal).reload.support_text, :blank?
  end

  test "administrators edit it, starting from what members see" do
    sign_in :david
    get support_page_url
    assert_select "a[href=?]", edit_support_page_path

    get edit_support_page_url
    assert_select "lexxy-editor[name='account[support_text]'][value*='julio@pickingnuggets.com']"

    patch support_page_url, params: { account: { support_text: "<h2>Help</h2><p>Ask in 👋 Hi.</p>" } }
    assert_redirected_to support_page_url

    sign_in :kevin
    get support_page_url
    assert_select ".lexxy-content h2", "Help"
    assert_select ".lexxy-content", text: /Ask in 👋 Hi\./
    assert_select ".lexxy-content a[href^='mailto:']", count: 0
  end

  test "it sits at the bottom of Rooms, looking unlike a room" do
    sign_in :kevin
    get user_sidebar_url

    assert_select "#rooms_list > a.support-link:last-child[href=?]", support_page_path, text: /Support & tips/
    assert_select "#shared_rooms a.support-link", count: 0
  end
end
