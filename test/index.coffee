filenameMediaQuery = require '../'
concat = require 'concat-stream'
gulp = require 'gulp'
should = require 'should'

describe 'gulp-filename-media-query', ->
	it 'should fail with illegal file extensions', ( done ) ->
		gulp
			.src 'test/fixture/invalid/@screen.scss'
			.pipe filenameMediaQuery()
			.on 'error', ( error ) ->
				should.exist error
				done()

	it 'should wrap empty files', ( done ) ->
		gulp
			.src 'test/fixture/empty/@screen.css'
			.pipe filenameMediaQuery()
			.pipe concat ( files ) ->
				files[0]
					.contents
					.toString()
					.should.containEql 'screen'
				done()

	it 'should refuse to process invalid filename syntax', ( done ) ->
		gulp
			.src 'test/fixture/invalid/@screen-42.css'
			.pipe filenameMediaQuery()
			.on 'error', ( error ) ->
				should.exist error
				done()

	it 'should wrap valid files', ( done ) ->
		gulp
			.src 'test/fixture/valid/@screen.css'
			.pipe filenameMediaQuery()
			.pipe concat ( files ) ->
				files[0]
					.contents
					.toString()
					.should.be.exactly '@media screen {\n\tdiv {\n\t\tdisplay: block;\n\t}\n}'
				done()

	it 'should support sophisticated media queries', ( done ) ->
		gulp
			.src 'test/fixture/valid/@print--w+400px--w-800px.css'
			.pipe filenameMediaQuery()
			.pipe concat ( files ) ->
				files[0]
					.contents
					.toString()
					.should.containEql 'print and ( min-width: 400px ) and ( max-width: 800px )'
				done()

	it 'should automatically prefix a media type if supplied as an option', ( done ) ->
		gulp
			.src 'test/fixture/valid/@min-width-400px.css'
			.pipe filenameMediaQuery( mediaType: 'tv' )
			.pipe concat ( files ) ->
				files[0]
					.contents
					.toString()
					.should.containEql 'tv'
				done()

	it 'should allow manipulating the expressions with the evaluation callback', ( done ) ->
		gulp
			.src 'test/fixture/valid/@print--w+400px--w-800px.css'
			.pipe filenameMediaQuery
				on:
					evaluation: ( _, expressions ) -> [ _, expressions.map( ( _ ) -> _.unit = 'rem'; _ ) ]
			.pipe concat ( files ) ->
				files[0]
					.contents
					.toString()
					.should.containEql '400rem'
				done()