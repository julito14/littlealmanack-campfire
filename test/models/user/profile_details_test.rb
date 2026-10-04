require "test_helper"

class User::ProfileDetailsTest < ActiveSupport::TestCase
  setup do
    @user = users(:jz)
  end

  test "everything is optional" do
    assert @user.valid?
    assert_empty @user.books_list
    assert_empty @user.profile_links
  end

  test "blank answers are stored as nothing" do
    @user.update!(location: "  ", books: "\n", website_url: " ", x_handle: "", linkedin_url: "", instagram_handle: " ")

    assert_nil @user.location
    assert_nil @user.books
    assert_empty @user.profile_links
  end

  test "usernames can be typed with an @ or pasted as a profile link" do
    @user.update!(x_handle: "@reader", instagram_handle: "https://www.instagram.com/reader.books/?hl=en")

    assert_equal "reader", @user.x_handle
    assert_equal "reader.books", @user.instagram_handle
    assert_equal "https://x.com/reader", @user.profile_links["X"]
    assert_equal "https://www.instagram.com/reader.books", @user.profile_links["Instagram"]
  end

  test "a pasted link to a post still finds the username" do
    @user.update!(x_handle: "x.com/reader/status/123")
    assert_equal "reader", @user.x_handle
  end

  test "websites get https when typed without it" do
    @user.update!(website_url: "littlealmanack.com")
    assert_equal "https://littlealmanack.com", @user.website_url
  end

  test "linkedin takes a profile link or just the username" do
    @user.update!(linkedin_url: "linkedin.com/in/reader")
    assert_equal "https://linkedin.com/in/reader", @user.linkedin_url

    @user.update!(linkedin_url: "@reader")
    assert_equal "https://www.linkedin.com/in/reader", @user.linkedin_url
  end

  test "only real web links are accepted" do
    [ "javascript:alert(1)", "javascript://%0Aalert(1)", "data:text/html,hi", "not a site" ].each do |link|
      @user.website_url = link
      assert_not @user.valid?, "#{link} should be rejected"
    end
  end

  test "linkedin links must point at linkedin" do
    @user.linkedin_url = "https://evil.example/linkedin.com/in/reader"
    assert_not @user.valid?

    @user.linkedin_url = "https://notlinkedin.com/in/reader"
    assert_not @user.valid?
  end

  test "usernames can't contain spaces or symbols" do
    @user.x_handle = "two words"
    assert_not @user.valid?
  end

  test "location and books have length limits" do
    @user.location = "x" * 101
    assert_not @user.valid?

    @user.location = nil
    @user.books = "x" * 301
    assert_not @user.valid?
  end

  test "books are listed one per line" do
    @user.update!(books: "The Intelligent Investor\n\n  Poor Charlie's Almanack  \n")
    assert_equal [ "The Intelligent Investor", "Poor Charlie's Almanack" ], @user.books_list
  end
end
