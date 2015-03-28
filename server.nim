# example.nim
# import jester, asyncdispatch, json, sequtils
import jester, asyncdispatch
# import lib/graph

# var
#   g : Graph
#   mapper : Mapper

routes:
  get "/api/findscale":
    # var g = load_bin_graph()
    # var mapper = init_mapper()
    # let start = request.params["start"]
    # let stop = request.params["stop"]
    # echo "Pathing..."
    # var res = find_path_s(g,mapper,start,stop)
    # echo "Done Pathing..."
    # if not res.worked: resp "{\"scale\":\"bad\"}"
    # let path = @["hi"]
    # let pathj = %mapIt(path,JsonNode, %it)
    # let q = 1
    # let q = if res.bid: 2 else: 1
    # resp "{\"status\":\"ok\", \"scale\": "& $pathj &", \"quality\": "& $q &"}"
    resp "Hello World"

# echo "Loading..."
# g = load_bin_graph()
# mapper = init_mapper()
# echo "Serving..."
runForever()
