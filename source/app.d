import std.stdio;
import vibe.d;
import graph;

Graph wikiGraph;

@path("/api")
interface Api {
  //struct Result {
  //  string status;
  //  string[] scale;
  //  int quality;
  //}

  @path("findscale")
  graph.Path getFindScale(string start, string stop);
}

class ApiImpl : Api {
  override:
  graph.Path getFindScale(string start, string stop) {
    return wikiGraph.rateWithScience(start, stop);
  }
}

void findScale(HTTPServerRequest req, HTTPServerResponse res) {
  enforceHTTP("start" in req.form, HTTPStatus.badRequest, "Missing start field.");
  enforceHTTP("stop" in req.form, HTTPStatus.badRequest, "Missing stop field.");
}

shared static this() {
  wikiGraph = new Graph("data");

  auto router = new URLRouter;
  router.registerRestInterface(new ApiImpl());
  router.get("*", serveStaticFiles("./public/"));

  auto settings = new HTTPServerSettings;
  settings.port = 5000;
  listenHTTP(settings, router);
}
