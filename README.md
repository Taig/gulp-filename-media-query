# Gulp Filename Media Query

[![Build Status](https://travis-ci.org/Taig/gulp-filename-media-query.svg?branch=master)](https://travis-ci.org/Taig/gulp-filename-media-query)

A Gulp Plugin that translates a specific filename syntax to a CSS media query and then wraps the file content accordingly.

## Usage

In order to qualify as a media query file the CSS filename must be prepended with an `@` character. If a media type (such as `screen` or `print`) should be used it has to be the first expression after the `@` character.

Expressions such as `min-width: 600px` are written as `min-width-640px`. A value is not mandatory, `color` is a valid expression as well.

The full CSS media query language features are [available as BNF](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Media_queries#Pseudo-BNF_(for_those_of_you_that_like_that_kind_of_thing)) . The media type prefix `not` and `only` are currently not supported.

Multiple expressions are linked with a double dash (`--`).

Commonly used expressions `min-width`, `max-width`, `min-height` and `max-height` can be abbreviated as `w+`, `w-`, `h+` and `h-`.

## Options

The plugin accepts an `options` object parameter with the following keys:

##### `mediaType`
default: `null`

Prepends a specified media type (such as `screen` or `print`) to every generated media query that does not provide a media type in its filename.

##### `on.evaluation`
default: `function( mediaType, expressions ) { return [ mediaType, expressions ] }`

Callback method that allows to modify the evaluated media query (e.g. converting `px` units to `em`).

## Examples

Valid filenames:

- `@print`
- `@tv`
- `@print--min-width-600px`
- `@min-width-30em`
- `@screen--color`
- `@min-width-500px--max-width-800px`
- `@w+500px`

Gulp configuration:

```js
gulp
  .src( '**/*.scss' )
  .pipe( sass() )
  .pipe( filenameMediaQuery( {
    mediaType: 'screen',
    on: {
      evaluation: function( mediaType, expressions ) {
        return [ mediaType, expressions.map( function( _ ) { _.unit = 'em'; } ) ]
      }
    }
   } ) )
  .pipe( concat( 'main.css' ) )
  .pipe( groupMediaQueries() )
  .pipe( gulp.dest( 'assets/' ) )
```
