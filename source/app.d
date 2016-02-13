import std.stdio, std.datetime;
import vibe.d;
import graph;

Graph wikiGraph;
TaskMutex mtx;

@path("/api")
interface Api {
  @path("findscale")
  graph.Path getFindScale(string start, string stop);
}

class ApiImpl : Api {
  override:
  graph.Path getFindScale(string start, string stop) {
    StopWatch sw = StopWatch(AutoStart.yes);
    writeln("Pathing from ", start, " to ", stop);
    mtx.lock();
    auto res = wikiGraph.rateWithScience(start, stop);
    mtx.unlock();
    sw.stop();
    writeln("Done pathing with result", res, " it took ", sw.peek().msecs, "ms");
    return res;
  }
}

shared static this() {
  writeln("Starting Rate With Science!");
  wikiGraph = new Graph("data");
  mtx = new TaskMutex;

  auto router = new URLRouter;
  router.registerRestInterface(new ApiImpl());
  router.get("*", serveStaticFiles("./public/"));

  auto settings = new HTTPServerSettings;
  settings.port = 5000;
  listenHTTP(settings, router);
}
