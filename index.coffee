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
		on:
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

			if extension isnt 'css'
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

			mediaType = evaluation[0]
			expressions = evaluation[1]

			# Build media query
			query = '@media '

			if mediaType isnt null
				query += mediaType

			if expressions.length
				query += ' and ' + expressions.map(
					( expression ) ->
						if expression.value is null
							"( #{expression.feature} )"
						else
							"( #{expression.feature}: #{expression.value}#{expression.unit} )"
				).join ' and '

			query +=
				' {' +
				( if file.contents.length then "\n\t#{file.contents.toString().split( '\n' ).join( '\n\t' )}\n" else '' ) +
				'}'

			file.contents = new buffer query

		this.push file
		callback()

module.exports = filenameMediaQuery