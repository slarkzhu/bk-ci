local cjson = require("cjson")

local bk_token, err = cookieUtil:get_cookie("BK-TOKEN")
ngx.log(ngx.ERR, "bk_access_token: ", bk_token)

if not bk_token then
  ngx.log(ngx.STDERR, "failed to read user request bk_token: ", err)
  ngx.exit(401)
  return
end


local ticket = string.gsub(bk_token, "\"", "")
ngx.header["x-devops-uid"] = ticket
ngx.header["x-devops-bk-token"] = "rzB9dCkGOKVYL-U8nDMDwANUG0UwYPLN82aQxk1efHg"
ngx.header["x-devops-access-token"] = "alJXviJhTNPl2KnFP4neTIlWRh32vY"
ngx.exit(200)