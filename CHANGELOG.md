# Changelog


## 6.0.1

  - [bug] Found two exceptions that hadn't been property referenced `MissingTypeAnnotationException` and `PathAlreadyDefinedException`

## 6.0.0

  - [breaking] A complete rewrite of the library, top to bottom, attempting to deal with a massive amount of annoyances and issues. Now instead of comparing the whole tree to a half-assed `dry-types` schema I only test end nodes. Instead of clumsily traversing the tree the library gracefully understands the preciarous nature of the input. I also went ahead and made it a little more composable. Finally as a last feature the library now by default returns a list of issues rather than balking on the first problem.

## 5.1.0

  - Adding the ability to neatly define a subschema without the extra keyword

## 5.0.0

Undocumented.

## 4.0.0

Undocumented.

## 3.0.0

Undocumented.

## 2.0.0

Undocumented.

## 1.0.0

  - Initial release
