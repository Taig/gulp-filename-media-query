// Generated by CoffeeScript 1.7.1
(function() {
  'use strict';
  var buffer, filenameMediaQuery, path, through, util, _,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  _ = require('lodash');

  buffer = require('buffer').Buffer;

  path = require('path');

  through = require('through2');

  util = require('gulp-util');

  filenameMediaQuery = function(options) {
    var units;
    units = ['ch', 'cm', 'em', 'ex', 'in', 'mm', 'pc', 'pt', 'px', 'rem', 'vh', 'vw'];
    options = _.merge({
      mediaType: null,
      suffix: ['css'],
      on: {
        build: function(mediaType, expressions, block) {
          var query;
          query = '@media ';
          if (mediaType !== null) {
            query += mediaType;
          }
          if (expressions.length) {
            query += ' and ' + expressions.map(function(_) {
              if (_.value === null) {
                return "( " + _.feature + " )";
              } else {
                return "( " + _.feature + ": " + _.value + _.unit + " )";
              }
            }).join(' and ');
          }
          return query + ' {' + (block.length ? "\n\t" + (block.split('\n').join('\n\t')) + "\n" : '') + '}';
        },
        evaluation: function(mediaType, expressions) {
          return [mediaType, expressions];
        }
      }
    }, options);
    return through.obj(function(file, _, callback) {
      var error, evaluation, expression, expressions, extension, feature, mediaType, name, properties, regex, unit, value, _i, _len;
      if (file.isStream()) {
        callback();
        return this.emit('error', new util.PluginError('gulp-filename-media-query', 'Streaming is not supported'));
      }
      if (file.isNull()) {
        this.push(file);
        return callback();
      }
      name = path.basename(file.path);
      if (name[0] === '@') {
        extension = path.extname(name).substr(1);
        if (options.suffix !== null && __indexOf.call(options.suffix, extension) < 0) {
          callback();
          return this.emit('error', new util.PluginError('gulp-filename-media-query', "Only " + options.suffix + " files supported (*." + extension + ")"));
        }
        name = name.substr(1, name.indexOf("." + extension) - 1);
        properties = name.split('--');
        expressions = [];
        if (/^[a-z-]+$/.test(properties[0])) {
          mediaType = properties.shift();
        } else {
          mediaType = options.mediaType;
        }
        for (_i = 0, _len = properties.length; _i < _len; _i++) {
          expression = properties[_i];
          try {
            feature = expression.match(new RegExp("^([\\a-z-+]+)\\d*"))[1];
            value = null;
            if (feature.length < expression.length) {
              regex = expression.match(new RegExp("(\\d+)(" + (units.join('|')) + ")$"));
              value = regex[1];
              unit = regex[2];
            }
          } catch (_error) {
            error = _error;
            return this.emit('error', new util.PluginError('gulp-filename-media-query', "Malformed filename syntax (" + expression + ")"));
          }
          switch (feature) {
            case 'w+':
              feature = 'min-width';
              break;
            case 'w-':
              feature = 'max-width';
              break;
            case 'h+':
              feature = 'min-height';
              break;
            case 'h-':
              feature = 'max-height';
          }
          if (feature[feature.length - 1] === '-') {
            feature = feature.substr(0, feature.length - 1);
          }
          expressions.push({
            feature: feature,
            value: value,
            unit: unit
          });
        }
        evaluation = options.on.evaluation(mediaType, expressions);
        if (!evaluation || evaluation.length !== 2) {
          callback();
          return this.emit('error', new util.PluginError('gulp-filename-media-query', "Invalid evaluation callback method given"));
        }
        file.contents = new buffer(options.on.build(evaluation[0], evaluation[1], file.contents.toString(), extension));
      }
      this.push(file);
      return callback();
    });
  };

  module.exports = filenameMediaQuery;

}).call(this);
