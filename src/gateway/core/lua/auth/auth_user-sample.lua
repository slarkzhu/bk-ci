local cjson = require("cjson")

local bk_jwt, err = cookieUtil:get_cookie("BK-JWT")
if not bk_jwt then
  ngx.log(ngx.STDERR, "failed to read user request bk_jwt: ", err)
  ngx.exit(401)
  return
end

jwt_obj = jwt:verify("y6im5#t#s2a!kk@^u4pagt(ow+_+tij)34f-3upay7kugo%a@3", bk_jwt)
ngx.log(ngx.STDERR, "verified: ", jwt_obj.verified)
if not jwt_obj.verified then
  ngx.log(ngx.STDERR, "failed to verify bk_jwt: ", jwt_obj.reason)
  ngx.exit(401)
  return
end

ngx.header["x-devops-uid"] = jwt_obj.payload.email
ngx.header["x-devops-bk-token"] = "rzB9dCkGOKVYL-U8nDMDwANUG0UwYPLN82aQxk1efHg"
ngx.header["x-devops-access-token"] = "alJXviJhTNPl2KnFP4neTIlWRh32vY"
ngx.exit(200)