#[macro_use]
extern crate serde_derive;
use ratewithscience::IndexedGraph;
use rouille::{router, Response};
use std::fs::File;
use std::path::Path;
use std::sync::Mutex;
use std::time::Instant;

#[derive(Serialize)]
struct PathResponse {
    status: usize,
    path: Vec<String>,
}

fn main() {
    // This example shows how to serve static files with rouille.

    println!("Loading...");
    let g_mutex = Mutex::new(IndexedGraph::new(Path::new("data")).unwrap());

    // Note that like all examples we only listen on `localhost`, so you can't access this server
    // from another machine than your own.
    println!("Loaded! Now listening on http://localhost:5000/");

    rouille::start_server("localhost:5000", move |request| {
        {
            let response = rouille::match_assets(&request, "public");
            if response.is_success() {
                return response;
            }
        }

        router!(request,
            (GET) (/) => {
                let file = match File::open("public/index.html") {
                    Ok(f) => f,
                    Err(_) => return Response::empty_404(),
                };

                Response::from_file("text/html", file)
            },
            (GET) (/api/findscale) => {
                let start = request.get_param("start").unwrap();
                let stop = request.get_param("stop").unwrap();
                let now = Instant::now();
                let g = g_mutex.lock().unwrap();
                let (status, path) = g.rate_with_science(&start, &stop).unwrap();
                println!("Found {:?} for '{}' -> '{}' in {}ms", status, start, stop, now.elapsed().as_millis());
                Response::json(&PathResponse { status: status as usize, path })
            },
            _ => rouille::Response::empty_404()
        )
    });
}
