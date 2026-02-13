# LSNews - News Article Management

LSNews manages news articles for the OGo newsboard.
Articles can be related to each other through a
many-to-many link table.

**Built as:** `LSNews.cmd` (command bundle)


## Dependencies

- LSFoundation


## Registered Commands

### `newsarticle` Domain

| Command | Description |
|----------------------------------------|--------------------------|
| `newsarticle::new`                     | Create article           |
| `newsarticle::set`                     | Update article           |
| `newsarticle::delete`                  | Delete article           |
| `newsarticle::get`                     | Fetch articles           |
| `newsarticle::get-related-articles`    | Get related articles     |
| `newsarticle::set-related-articles`    | Set related articles     |

### `newsarticlelink` Domain

| Command | Description |
|----------------------------------------|--------------------------|
| `newsarticlelink::new`                 | Create article link      |
| `newsarticlelink::delete`              | Delete article link      |


## Key Classes

| Class | Base Class | Purpose |
|-----------------------------------|-------------------------|----------------|
| `LSNewNewsArticleCommand`         | `LSDBObjectNewCommand`  | Create article |
| `LSSetNewsArticleCommand`         | `LSDBObjectSetCommand`  | Update article |
| `LSDeleteNewsArticleCommand`      | `LSDBObjectDeleteCommand`| Delete article|
| `LSGetRelatedArticlesCommand`     | `LSDBObjectBaseCommand` | Fetch related  |
| `LSSetRelatedArticlesCommand`     | `LSDBObjectBaseCommand` | Set relations  |


## Source Structure

A small module with 5 source files:

- `LSNewNewsArticleCommand.m` - Create with validation
- `LSSetNewsArticleCommand.m` - Update article fields
- `LSDeleteNewsArticleCommand.m` - Delete with cleanup
- `LSGetRelatedArticlesCommand.m` - Follow article links
- `LSSetRelatedArticlesCommand.m` - Manage article links
