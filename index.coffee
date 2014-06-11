'use strict'

buffer = require( 'buffer' ).Buffer
path = require 'path'
through = require 'through2'
util = require 'gulp-util'

filenameMediaQuery = ->
	units = [
		'ch'
		'cm'
		'em'
		'ex'
		'in'
		'mm'
		'pc'
		'pt'
		'px'
		'rem'
		'vh'
		'vw'
	]

	extensions = [
		'css'
		'sass'
		'scss'
	]

	regex =
		file: new RegExp "/(([<>]\\d+(#{units.join '|'}))|(=\\d+(#{units.join '|'})-\\d+(#{units.join '|'})))\\.(#{extensions.join '|'})$"
		value: new RegExp "[<>=](.+)\\.(#{extensions.join '|'})"

	through.obj ( file, _, callback ) ->
		if regex.file.test file.path
			# Prepare media query
			query = '@media screen and '
			name = path.basename file.path
			sign = name[0]
			suffix = path.extname( name ).substring 1
			dimension = name.replace regex.value, '$1'

			switch sign
				when '<' then query += "( max-width: #{dimension} )"
				when '>' then query += "( min-width: #{dimension} )"
				when '='
					dimension = dimension.split '-'
					query += "( min-width: #{dimension[0]} ) and ( max-width: #{dimension[1]} )"
				else
					throw new util.PluginError 'gulp-filename-media-query', 'Illegal file prefix'

			if suffix is 'sass'
				query += '\n\t' + file.contents.toString().split( '\n' ).join '\n\t'
			else
				query += ' {\n'
				query += file.contents.toString().join '\n'
				query += '\n}'

			file.contents = new buffer query

		this.push file
		callback()

module.exports = filenameMediaQuery