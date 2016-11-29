
- implement routing algorithm
  - change node structure
  - only allow http-method matching at leafs
  - be able to list all routes
  - generate url-helpers
  - capture groups in url like "users/@id"
    - do it like path(id => /[0-9]+/) { ... }
