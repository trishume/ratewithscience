use rusqlite::OptionalExtension;
use rusqlite::{Connection, OpenFlags};
use std::error::Error;
use std::path::Path;

use crate::PageByteOffset;

pub struct Index {
    connection: Connection,
}

pub type Result<T> = std::result::Result<T, Box<dyn Error>>;

impl Index {
    pub fn new(db_path: &Path) -> Result<Self> {
        let connection = Connection::open_with_flags(db_path, OpenFlags::SQLITE_OPEN_READ_ONLY)?;
        Ok(Self { connection })
    }

    pub fn title_to_page(&self, title: &str) -> Result<Option<PageByteOffset>> {
        let res = self
            .connection
            .query_row(
                "SELECT offset FROM pages WHERE title = ? COLLATE NOCASE LIMIT 1",
                &[title],
                |row| row.get(0),
            )
            .optional()?;
        Ok(res)
    }

    pub fn page_to_title(&self, page: PageByteOffset) -> Result<Option<String>> {
        let res = self
            .connection
            .query_row(
                "SELECT title FROM pages WHERE offset = ? LIMIT 1",
                &[page],
                |row| row.get(0),
            )
            .optional()?;
        Ok(res)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_index() {
        let index = Index::new(Path::new("data/xindex-nocase.db")).unwrap();
        let page = index.title_to_page("David Hasselhoff").unwrap().unwrap();
        let title = index.page_to_title(page).unwrap().unwrap();
        assert_eq!(title, "David Hasselhoff");
    }
}
