import sequtils, queues, db_sqlite, strutils, algorithm

type
  Graph* = seq[int32]
  Mapper* = TDbConn
  Page = int32
  PathRes = tuple[path:seq[int32],bid:bool,worked:bool]
  PathSRes = tuple[path:seq[string],bid:bool,worked:bool]

const
  kPageUserDataField = 0
  kPageLinksField = 1
  kPageBidLinksField = 2
  kPageHeaderSize = 3
  kFirstPageIndex = 4

let
  titleToIdQuery = sql"SELECT offset FROM pages WHERE title = ? COLLATE NOCASE LIMIT 1"
  idToTitleQuery = sql"SELECT title FROM pages WHERE offset = ? LIMIT 1"

proc offset*[A](some: ptr A; b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))
iterator iterPtr*[A](some: ptr A; num: int): A =
  for i in 0.. <num:
    yield some.offset(i)[]
proc load_bin_graph*() : Graph =
  echo "loading graph..."
  var f : File
  discard open(f,"data/indexbi.bin")
  defer: close(f)
  let size : int = getFileSize(f).int
  let count = size /% 4
  var s : seq[int32]
  newSeq(s, count)
  shallow(s)
  discard readBuffer(f,addr(s[0]),size)
  return s

iterator graph_links(g : Graph, p : Page, field : int32) : Page =
  block:
    let ind = p /% 4
    let link_count = g[ind + field]
    let start = ind+kPageHeaderSize
    for i in start.. <(start+link_count):
      yield g[i]
iterator all_pages(g : Graph) : Page =
  block:
    var i = kFirstPageIndex
    while i < g.len:
      yield (i*4).Page
      i += kPageHeaderSize+g[i+kPageLinksField]

proc user_data(g : Graph, p : Page) : int32 =
  g[p /% 4 + kPageUserDataField]
proc set_user_data(g : var Graph, p : Page, n : int32) =
  g[p /% 4 + kPageUserDataField] = n

proc shortest_path(g : var Graph, start : Page,
                   stop : Page, lenField : int32 = kPageBidLinksField) : seq[int32] =
  var q : Queue[int32] = initQueue[int32]()
  q.add(start)
  while true:
    if q.len == 0: return @[]
    var page = q.dequeue()
    if page == stop: break
    for linked in graph_links(g,page,lenField):
      if g.user_data(linked) == 0:
        g.set_user_data(linked, page)
        q.add(linked)
  # kk we have the thing, find path
  var cur_page = stop
  var path = @[stop]
  while cur_page != start:
    cur_page = g.user_data(cur_page)
    path.add(cur_page)
  reverse(path)
  return path

proc clear_marks(g : var Graph) =
  for p in all_pages(g):
    set_user_data(g,p,0)

proc find_path(g : var Graph, start : Page,
               stop : Page) : PathRes =
  let bid_path = shortest_path(g,start,stop,kPageBidLinksField)
  g.clear_marks()
  if bid_path.len > 0:
    return (path: bid_path, bid: true, worked: true)
  let path = shortest_path(g,start,stop,kPageLinksField)
  g.clear_marks()
  if path.len > 0:
    return (path: path, bid: false, worked: true)
  return (path: @[], bid: false, worked: false)

proc title_to_page(m : Mapper, title : string) : Page =
  let r = m.getRow(titleToIdQuery,title)
  if r[0] == "": return 0
  return parseInt(r[0]).int32
proc page_to_title(m : Mapper, p : Page) : string =
  let r = m.getRow(idToTitleQuery,p)
  if r[0] == "": return ""
  return r[0]

proc find_path_s*(g : var Graph, m : Mapper,
                 start : string, stop : string) : PathSRes =
  let p1 = m.title_to_page(start)
  let p2 = m.title_to_page(stop)
  echo start, "->", stop,"      ",p1,"->",p2
  if p1 == 0 or p2 == 0:
    echo "Fail1"
    return (path: @[], bid: false, worked: false)
  let res = g.find_path(p1,p2)
  if not res.worked:
    echo "Fail2"
    return (path: @[], bid: false, worked: false)
  let path_s = mapIt(res.path,string,page_to_title(m,it))
  return (path: path_s, bid: res.bid, worked: true)

proc init_mapper*() : Mapper =
  open("data/xindex.db","","","")

when isMainModule:
  var data = load_bin_graph()
  var conn = open("data/xindex.db","","","")
  echo conn.title_to_page("alphabet")
  echo conn.page_to_title(2664)
  echo data.len
  echo find_path(data, 312420, 2664)
  echo find_path_s(data,conn, "alphabet", "a")
