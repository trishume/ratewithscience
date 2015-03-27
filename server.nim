# example.nim
import jester, asyncdispatch

routes:
  get "/test":
    resp "Hello world"

runForever()