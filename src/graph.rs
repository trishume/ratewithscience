use byteorder::{LittleEndian, ReadBytesExt};
use std::collections::VecDeque;
use std::fs::File;
use std::io;
use std::io::BufReader;
use std::path::Path;

use crate::PageByteOffset;

type PageIndex = usize;

fn to_i(p: PageByteOffset) -> PageIndex {
    (p / 4) as usize
}

const FILE_VERSION_INDEX: usize = 0;
const FILE_HEADER_SIZE_INDEX: usize = 2;
const FILE_PAGE_HEADER_SIZE_INDEX: usize = 3;

const PAGE_USER_DATA_FIELD: usize = 0;
const PAGE_LINKS_FIELD: usize = 1;
const PAGE_BID_LINKS_FIELD: usize = 2;

pub struct Graph {
    g: Vec<u32>,
    page_header_size: usize,
    first_page_index: PageIndex,
    page_count: usize,
}

#[derive(Copy, Clone)]
pub enum SearchMode {
    Unidirectional,
    Bidirectional,
}

impl Graph {
    pub fn new(file: &Path) -> io::Result<Self> {
        let file = File::open(file)?;
        let size = file.metadata()?.len();
        assert!(size % 4 == 0);
        let len = size / 4;

        let mut reader = BufReader::new(file);
        let mut g = Vec::with_capacity(len as usize);

        for _ in 0..len {
            g.push(reader.read_u32::<LittleEndian>()?);
        }

        assert_eq!(g[FILE_VERSION_INDEX], 2);

        let mut s = Self {
            page_header_size: to_i(g[FILE_PAGE_HEADER_SIZE_INDEX]),
            first_page_index: to_i(g[FILE_HEADER_SIZE_INDEX]),
            page_count: 0,
            g,
        };
        s.number_pages();

        Ok(s)
    }

    fn number_pages(&mut self) {
        let mut i = self.first_page_index;
        let mut count = 0;
        while i < self.g.len() {
            self.g[i + PAGE_USER_DATA_FIELD] = count;
            i += self.page_header_size + (self.g[i + PAGE_LINKS_FIELD] as usize);
            count += 1;
        }
        self.page_count = count as usize;
    }

    fn links(&self, p: PageByteOffset, len_field: usize) -> &[u32] {
        let ind = to_i(p);
        let link_count = self.g[ind + len_field] as usize;
        let start = ind + self.page_header_size;
        &self.g[start..(start + link_count)]
    }

    fn page_id(&self, p: PageByteOffset) -> usize {
        self.g[to_i(p) + PAGE_USER_DATA_FIELD] as usize
    }

    pub fn shortest_path(
        &self,
        start: PageByteOffset,
        stop: PageByteOffset,
        mode: SearchMode,
    ) -> Option<Vec<PageByteOffset>> {
        let len_field = match mode {
            SearchMode::Unidirectional => PAGE_LINKS_FIELD,
            SearchMode::Bidirectional => PAGE_BID_LINKS_FIELD,
        };

        let mut marks: Vec<PageByteOffset> = vec![0; self.page_count];
        let mut queue = VecDeque::with_capacity(1024);
        queue.push_back(start);
        loop {
            let page = match queue.pop_front() {
                Some(page) => page,
                None => return None,
            };
            if page == stop {
                break;
            }

            for linked in self.links(page, len_field) {
                let id = self.page_id(*linked);
                if marks[id] == 0 {
                    marks[id] = page;
                    queue.push_back(*linked);
                }
            }
        }

        // figure out path from the marks
        let mut cur_page = stop;
        let mut path = vec![stop];
        while cur_page != start {
            cur_page = marks[self.page_id(cur_page)];
            path.push(cur_page);
        }
        path.reverse();

        return Some(path);
    }

    pub fn shortest_bidir_path_fallback(
        &self,
        start: PageByteOffset,
        stop: PageByteOffset,
    ) -> Option<(SearchMode, Vec<PageByteOffset>)> {
        self.shortest_path(start, stop, SearchMode::Bidirectional)
            .map(|x| (SearchMode::Bidirectional, x))
            .or_else(|| {
                self.shortest_path(start, stop, SearchMode::Unidirectional)
                    .map(|x| (SearchMode::Unidirectional, x))
            })
    }
}
