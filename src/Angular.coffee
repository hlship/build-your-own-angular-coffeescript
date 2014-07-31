_.mixin
  isArrayLike: (obj) ->
    return false if (_.isNull obj) or (_.isUndefined obj)

    _.isNumber obj.length