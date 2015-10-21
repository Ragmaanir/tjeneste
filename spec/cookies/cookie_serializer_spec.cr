require "../spec_helper"

module CookiesSpec

  class CookieSerializerTest < Minitest::Test
    private def cookie_request(value)
      headers = HTTP::Headers.new
      headers["Cookie"] = value
      req = HTTP::Request.new("GET", "/test", headers)
    end

    private def read_cookies(cookie_string)
      s = Tjeneste::Cookies::CookieSerializer.new
      req = cookie_request(cookie_string)
      s.read(req)
    end

    private def rejects(cookie_string)
      assert read_cookies(cookie_string).empty?
    end

    private def parses(cookie_string, result)
      assert read_cookies(cookie_string) == result
    end

    def test_reading_cookie_from_request
      parses(
        "id=123; other=te%=st; anotherone=234asd",
        {"id" => "123", "other" => "te%=st", "anotherone" => "234asd"}
      )

      parses(
        "id=123; anotherone=the-value-here",
        {"id" => "123", "anotherone" => "the-value-here"}
      )
    end

    def test_parsing_of_quoted_values
      parses(
        %{id="123"; anotherone="the-value-here"},
        {"id" => "123", "anotherone" => "the-value-here"}
      )
    end

    def test_tolerates_extra_semicolon_at_the_end
      parses("id=1;", {"id" => "1"})
      parses("id=1; other=5", {"id" => "1", "other" => "5"})
    end

    def test_reading_the_same_cookie_name_twice
      parses(
        "id=123; id=456",
        {"id" => "456"}
      )
    end

    def test_reading_malformed_cookie_from_request
      rejects("id=1\n23")
      rejects("id=1\t23")
      rejects("id=1 23")
      rejects("id=1;23")
    end
  end

end
