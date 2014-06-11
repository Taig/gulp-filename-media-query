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

	files = {}

	collect = ( file, _, callback ) ->
		# Check whether the file is a valid media query stylesheet
		if regex.file.test file.path
			name = path.basename file.path

			if not files.hasOwnProperty name
				files[name] = []

			files[name].push file
		else
			this.push file

		callback()

	process = ( callback ) ->
		for name, group of files
			# Create proper media query
			query = '@media screen and '
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
					throw new util.PluginError 'gulp-filename-media-query', 'Illegal file extension'

			if suffix is 'sass'
				query += '\n\t' + group.map( ( file ) -> file.contents.toString().split( '\n' ).join( '\n\t' ) ).join( '\n' )
			else
				query += ' {\n'
				query += group.map( ( file ) -> file.contents.toString() ).join '\n'
				query += '\n}'

			this.push new util.File(
				cwd: group[0].cwd
				base: group[0].base
				path: group[0].path
				contents: new Buffer query
			)

		callback()

	through.obj collect, process

module.exports = filenameMediaQuery