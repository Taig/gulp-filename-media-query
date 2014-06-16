'use strict'

_ = require 'lodash'
buffer = require( 'buffer' ).Buffer
path = require 'path'
through = require 'through2'
util = require 'gulp-util'

filenameMediaQuery = ( options ) ->
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

	options = _.merge {
		mediaType: null
		suffix: [ 'css' ]
		on:
			build: ( mediaType, expressions, block ) ->
				query = '@media '

				if mediaType isnt null
					query += mediaType

				if expressions.length
					query += ' and ' + expressions.map(
						( _ ) ->
							if _.value is null
								"( #{ _.feature } )"
							else
								"( #{ _.feature }: #{ _.value }#{ _.unit } )"
					).join ' and '

				query += ' {' + ( if block.length then "\n\t#{ block.split( '\n' ).join( '\n\t' ) }\n" else '' ) + '}'
			evaluation: ( mediaType, expressions ) -> [ mediaType, expressions ]
	}, options

	through.obj ( file, _, callback ) ->
		if file.isStream()
			callback()
			return this.emit 'error', new util.PluginError( 'gulp-filename-media-query', 'Streaming is not supported' )

		if file.isNull()
			this.push file
			return callback()

		name = path.basename( file.path )

		if name[0] is '@'
			extension = path.extname( name ).substr 1

			if options.suffix isnt null and extension not in options.suffix
				callback()
				return this.emit(
					'error',
					new util.PluginError 'gulp-filename-media-query', "Only *.css files supported (*.#{extension})"
				)

			name = name.substr( 1, name.indexOf( ".css" ) - 1 )
			properties = name.split '--'
			expressions = []

			# Extract media type or fall back to options default
			if /^[a-z-]+$/.test properties[0]
				mediaType = properties.shift()
			else
				mediaType = options.mediaType

			# Reformat expressions
			for expression in properties
				try
					feature = expression.match( new RegExp( "^([\\a-z-+]+)\\d*" ) )[1]
					value = null

					if feature.length < expression.length
						regex = expression.match( new RegExp( "(\\d+)(#{units.join '|'})$" ) )
						value = regex[1]
						unit = regex[2]
				catch error
					return this.emit(
						'error',
						new util.PluginError 'gulp-filename-media-query', "Malformed filename syntax (#{expression})"
					)

				# Detect and replace shortcuts
				switch feature
					when 'w+' then feature = 'min-width'
					when 'w-' then feature = 'max-width'
					when 'h+' then feature = 'min-height'
					when 'h-' then feature = 'max-height'

				# Remove trailing '-'
				if feature[feature.length - 1] is '-'
					feature = feature.substr( 0, feature.length - 1 )

				expressions.push { feature: feature, value: value, unit: unit }

			# Allow user to manipulate extracted media query expressions
			evaluation = options.on.evaluation( mediaType, expressions )

			if not evaluation or evaluation.length isnt 2
				callback()
				return this.emit(
					'error',
					new util.PluginError 'gulp-filename-media-query', "Invalid evaluation callback method given"
				)

			# Build media query
			file.contents = new buffer( options.on.build evaluation[0], evaluation[1], file.contents.toString(), extension )

		this.push file
		callback()

module.exports = filenameMediaQuery