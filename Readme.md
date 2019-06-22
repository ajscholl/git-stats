# git-stats

This tool walks the history of a git repository and accumulates the insertions and deletions of each user.
After installing `git-stats` in your `$PATH` simply run `git-stats` (or `git stats`) somewhere in your git repository.

## .git-authors

You can define mappings from one author to another.
Using this, you can merge the contributions of a person using different names.

Example:

    Git scores (in LOC):                  Inserted        Deleted     Difference
    Person 1 - Work:                       +36,858        -22,122        +14,736
    Person 1 - Home:                       +22,109        -12,499         +9,610

Contents of `~/.git-authors`:

    Person 1 - Work = Person 1
    Person 1 - Home = Person 1

Running `git-stats` now produces the following output:

    Git scores (in LOC):                  Inserted        Deleted     Difference
    Person 1:                              +58,967        -34,621        +24,346
