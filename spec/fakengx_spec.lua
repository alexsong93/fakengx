require 'spec.helper'

context('fakengx', function()

  before(function()
    ngx = fakengx.new()
  end)

  test('instance type', function()
    assert_type(ngx, 'table')
  end)

  test('constants', function()
    assert_equal(ngx.DEBUG, 8)
    assert_equal(ngx.HTTP_GET, 'GET')
    assert_equal(ngx.HTTP_OK, 200)
    assert_equal(ngx.HTTP_BAD_REQUEST, 400)
  end)

  test('static', function()
    assert_equal(ngx.status, 200)
    assert_tables(ngx.var, {})
    assert_tables(ngx.arg, {})
    assert_tables(ngx.header, {})
  end)

  test('internal registries', function()
    assert_equal(ngx._body, "")
    assert_equal(ngx._log, "")
    assert_tables(ngx._captures, { stubs = {} })
  end)

  test('_captures.length()', function()
    assert_equal(ngx._captures:length(), 0)
  end)

  test('_captures.stub()', function()
    ngx.location.stub("/subrequest")
    ngx.location.stub("/subrequest", { body = "ABC", method = "POST" }, { status = 201 })
    ngx.location.stub("/subrequest", { args = { b = 1, a = 2 } }, { body = "OK" })
    assert_equal(ngx._captures:length(), 3)

    local stub
    stub = ngx._captures.stubs[1]
    assert_equal(stub.uri, "/subrequest")
    assert_tables(stub.opts, { })
    assert_tables(stub.res, { status = 200, headers = {}, body = "" })

    stub = ngx._captures.stubs[2]
    assert_equal(stub.uri, "/subrequest")
    assert_tables(stub.opts, { body = "ABC", method = "POST" })
    assert_tables(stub.res, { status = 201, headers = {}, body = "" })

    stub = ngx._captures.stubs[3]
    assert_equal(stub.uri, "/subrequest")
    assert_tables(stub.opts, { args = "a=2&b=1" })
    assert_tables(stub.res, { status = 200, headers = {}, body = "OK" })
  end)

  test('_captures.find()', function()
    local s0 = ngx.location.stub("/subrequest", { }, { status = 200 })
    local s1 = ngx.location.stub("/subrequest", { method = "GET" }, { status = 200 })
    local s2 = ngx.location.stub("/subrequest", { body = "ABC", method = "POST" }, { status = 201, headers = { Location = "http://host/resource/1" } })
    local s3 = ngx.location.stub("/subrequest", { args = { b = 1, a = 2 } }, { body = "OK" })

    assert_nil(ngx._captures:find("/not-registered", {}))
    assert_nil(ngx._captures:find("/not-registered"))

    assert_tables(ngx._captures:find("/subrequest"), s1.res)
    assert_tables(ngx._captures:find("/subrequest", { method = "GET" }), s1.res)
    assert_tables(ngx._captures:find("/subrequest", { method = "POST", body = "ABC" }), s2.res)
    assert_tables(ngx._captures:find("/subrequest", { body = "ABC" }), s1.res)
    assert_tables(ngx._captures:find("/subrequest", { args = "a=2&b=1" }), s3.res)
    assert_tables(ngx._captures:find("/subrequest", { args = { a = 2, b = 1 } }), s3.res)
    assert_tables(ngx._captures:find("/subrequest", { args = "b=1&a=1" }), s1.res)
    assert_tables(ngx._captures:find("/subrequest", { method = "POST" }), s0.res)
  end)

  test('print()', function()
    ngx.print("string")
    assert_equal(ngx._body, "string")
  end)

  test('say()', function()
    ngx.say("string")
    assert_equal(ngx._body, "string\n")
  end)

  test('log()', function()
    ngx.log(ngx.NOTICE, "string")
    assert_equal(ngx._log, "LOG(6): string\n")
  end)

  test('time()', function()
    assert_type(ngx.time(), 'number')
    assert_equal(ngx.time(), os.time())
  end)

  test('now()', function()
    assert_type(ngx.now(), 'number')
    assert(ngx.now() >= os.time())
    assert(ngx.now() <= (os.time() + 1))
  end)

  test('exit()', function()
    assert_equal(ngx.status, 200)
    assert_nil(ngx._exit)

    ngx.exit(ngx.HTTP_BAD_REQUEST)
    assert_equal(ngx.status, 400)
    assert_equal(ngx._exit, 400)

    ngx.exit(ngx.HTTP_OK)
    assert_equal(ngx.status, 400)
    assert_equal(ngx._exit, 200)
  end)

  test('escape_uri()', function()
    assert_equal(ngx.escape_uri("here [ & ] now"), "here+%5B+%26+%5D+now")
  end)

  test('unescape_uri()', function()
    assert_equal(ngx.unescape_uri("here+%5B+%26+%5D+now"), "here [ & ] now")
  end)

  test('encode_args()', function()
    assert_equal(ngx.encode_args({foo = 3, ["b r"] = "hello world"}), "b%20r=hello%20world&foo=3")
    assert_equal(ngx.encode_args({["b r"] = "hello world", foo = 3}), "b%20r=hello%20world&foo=3")
  end)

  test('crc32_short()', function()
    assert_type(ngx.crc32_short("abc"), 'number')
    assert_equal(ngx.crc32_short("abc"), 891568578)
    assert_equal(ngx.crc32_short("def"), 214229345)
  end)

  test('location.capture()', function()
    ngx.location.stub("/stubbed", {}, { body = "OK" })

    assert_error(function() ngx.location.capture("/not-stubbed") end)
    assert_not_error(function() ngx.location.capture("/stubbed") end)
    assert_tables(ngx.location.capture("/stubbed"), { status = 200, headers = {}, body = "OK" })
  end)

end)