# example.nim
import jester/jester, asyncdispatch, json, sequtils, locks,times
import lib/graph

var
  g : Graph
  mapper : Mapper
  mutex : TLock

routes:
  get "/api/findscale":
    # var g = load_bin_graph()
    # var mapper = init_mapper()
    let start = request.params["start"]
    let stop = request.params["stop"]
    echo "Pathing..."
    var t0 = cpuTime()
    acquire mutex
    var res = find_path_s(g,mapper,start,stop)
    release mutex
    echo "Done pathing, took: ", cpuTime() - t0
    if not res.worked:
      resp "{\"scale\":\"bad\"}"
    else:
      let path = res.path
      let pathj = %mapIt(path,JsonNode, %it)
      let q = if res.bid: 2 else: 1
      resp "{\"status\":\"ok\", \"scale\": "& $pathj &", \"quality\": "& $q &"}"

initLock mutex
echo "Loading..."
acquire mutex
g = load_bin_graph()
mapper = init_mapper()
release mutex
echo "Serving..."
runForever()
