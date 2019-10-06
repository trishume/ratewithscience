use std::error::Error;
use std::path::Path;
pub mod graph;
pub mod index;

use crate::graph::{Graph, SearchMode};
use crate::index::Index;

pub type PageByteOffset = u32;

pub type Result<T> = std::result::Result<T, Box<dyn Error>>;

#[derive(Debug, PartialEq)]
pub enum PathStatus {
    NoPath,
    BadStart,
    BadStop,
    Bidirectional,
    Unidirectional,
}

pub struct IndexedGraph {
    graph: Graph,
    index: Index,
}

impl IndexedGraph {
    pub fn new(data_dir: &Path) -> Result<Self> {
        let graph = Graph::new(&data_dir.join("indexbi.bin"))?;
        let index = Index::new(&data_dir.join("xindex-nocase.db"))?;
        Ok(Self { graph, index })
    }

    pub fn rate_with_science(&self, start: &str, stop: &str) -> Result<(PathStatus, Vec<String>)> {
        let p1 = match self.index.title_to_page(start)? {
            Some(page) => page,
            None => return Ok((PathStatus::BadStart, vec![])),
        };
        let p2 = match self.index.title_to_page(stop)? {
            Some(page) => page,
            None => return Ok((PathStatus::BadStop, vec![])),
        };
        let (status, path_offsets) = match self.graph.shortest_bidir_path_fallback(p1, p2) {
            Some((SearchMode::Bidirectional, path)) => (PathStatus::Bidirectional, path),
            Some((SearchMode::Unidirectional, path)) => (PathStatus::Unidirectional, path),
            None => (PathStatus::NoPath, vec![]),
        };
        let path: Result<Option<Vec<String>>> = path_offsets
            .into_iter()
            .map(|offset| self.index.page_to_title(offset))
            .collect();
        let path = path?.unwrap();
        Ok((status, path))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_graph() {
        let g = IndexedGraph::new(Path::new("data")).unwrap();
        let (status, path) = g
            .rate_with_science("David Hasselhoff", "Eiffel Tower")
            .unwrap();
        assert_eq!(status, PathStatus::Bidirectional);
        assert_eq!(&path[1], "EuroTrip");
    }
}
