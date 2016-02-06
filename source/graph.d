import std.stdio, std.path, std.file, std.algorithm, std.array, std.range;
import d2sqlite3;
import gfm.core.queue;

alias Page = uint;

enum PathStatus {
  NoPath,
  BadStart,
  BadStop,
  Bidirectional,
  Unidirectional
}

struct Path {
  PathStatus status;
  string[] path;
}

class Graph {
  Database db;
  uint[] g;

  enum pageUserDataField = 0;
  enum pageLinksField = 1;
  enum pageBidLinksField = 2;
  enum pageHeaderSize = 4;
  enum firstPageIndex = 4;

  this(string dataFolder) {
    db = Database(buildPath(dataFolder, "xindex.db"));
    writeln("Loading binary graph...");
    g = cast(Page[])read(buildPath(dataFolder, "indexbi.bin"));
    writefln("Loaded %d ints", g.length);
  }

  Page titleToPage(const(char[]) title) {
    auto statement = db.prepare("SELECT offset FROM pages WHERE title = :title COLLATE NOCASE LIMIT 1");
    statement.bind(":title",title);
    auto results = statement.execute();
    if(results.empty) return 0;
    return results.front.peek!Page(0);
  }

  string pageToTitle(Page p) {
    auto statement = db.prepare("SELECT title FROM pages WHERE offset = :offset LIMIT 1");
    statement.bind(":offset",p);
    auto results = statement.execute();
    if(results.empty) return "";
    return results.front.peek!string(0);
  }

  ref uint userData(Page p) {
    return g[p/4 + pageUserDataField];
  }

  Page[] links(Page p, uint countField) {
    uint ind = p / 4;
    uint linkCount = g[ind + countField];
    uint start = ind+pageHeaderSize;
    return g[start..(start+linkCount)];
  }

  auto allPages() {
    struct AllPageRange {
      uint[] g;
      uint i;
      bool empty() { return i >= g.length; }
      Page front() { return i*4; }
      void popFront() { i += pageHeaderSize+g[i+pageLinksField]; }
    }
    return AllPageRange(g, firstPageIndex);
  }

  void clearMarks() {
    foreach(p; allPages()) {
      userData(p) = 0;
    }
  }

  Page[] shortestPath(Page start, Page stop, uint lenField = pageBidLinksField) {
    auto q = new Queue!Page(1000);
    Page[] path;

    // trace the graph
    q.pushBack(start);
    while(true) {
      if(q.length() == 0) {
        clearMarks();
        return path;
      }
      Page page = q.popFront();
      if(page == stop) break;

      foreach(linked; links(page, lenField)) {
        if(userData(linked) == 0) {
          userData(linked) = page;
          q.pushBack(linked);
        }
      }
    }

    // figure out the path from the marks
    Page curPage = stop;
    path ~= stop;
    while(curPage != start) {
      curPage = userData(curPage);
      path ~= curPage;
    }
    reverse(path);

    clearMarks();
    return path;
  }

  Path pathResult(Page start, Page stop, uint lenField = pageBidLinksField) {
    Page[] pages = shortestPath(start, stop, lenField);
    PathStatus status = (lenField == pageBidLinksField) ? PathStatus.Bidirectional : PathStatus.Unidirectional;
    if(pages.length == 0) status = PathStatus.NoPath;
    return Path(status, pages.map!(p => pageToTitle(p)).array());
  }

  // the not-at-all-patented ratewith.science algorithm
  Path rateWithScience(string start, string stop) {
    Page p1 = titleToPage(start);
    if(p1 == 0) return Path(PathStatus.BadStart, []);
    Page p2 = titleToPage(stop);
    if(p2 == 0) return Path(PathStatus.BadStop, []);
    Path bidPath = pathResult(p1, p2, pageBidLinksField);
    if(bidPath.status == PathStatus.Bidirectional) return bidPath;
    Path uniPath = pathResult(p1, p2, pageLinksField);
    return uniPath;
  }
}

unittest {
  import dunit.toolkit;
  auto g = new Graph("data");

  writeln("Number of pages: ", g.allPages().walkLength());

  Page p = g.titleToPage("alphabet");
  string title = g.pageToTitle(p);
  title.assertEqual("Alphabet");

  Page p1 = g.titleToPage("David Hasselhoff");
  Page p2 = g.titleToPage("Eiffel Tower");
  auto path = g.pathResult(p1,p2);
  writeln(path);

  writeln(g.rateWithScience("Bicycle", "Eiffel Tower"));
  writeln(g.rateWithScience("Bicycle", "Pickles"));
}
