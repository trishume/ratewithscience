import sequtils

proc offset*[A](some: ptr A; b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))
iterator iterPtr*[A](some: ptr A; num: int): A =
  for i in 0.. <num:
    yield some.offset(i)[]

proc load_bin_graph() : seq[int32] =
  echo "loading graph..."
  var f : File
  discard open(f,"data/indexbi.bin")
  defer: close(f)
  let size : int = getFileSize(f).int
  let count = size /% 4
  let buf = createU(int32,count)
  defer: free(buf)
  discard readBuffer(f,cast[pointer](buf),size)
  # convert to seq
  var s = toSeq(iterPtr(buf,count))
  return s



when isMainModule:
  let data = load_bin_graph()
  echo data.len
