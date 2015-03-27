# example.nim
import jester, asyncdispatch, json, sequtils

routes:
  get "/api/findscale":
    let start = request.params["start"]
    let stop = request.params["stop"]
    var path = @["lol","wut","hi",start, stop]
    let pathj = %mapIt(path,JsonNode, %it)
    let q = 2
    resp "{\"status\":\"ok\", \"scale\": "& $pathj &", \"quality\": "& $q &"}"

runForever()
