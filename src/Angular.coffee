_.mixin
  isArrayLike: (obj) ->
    return false if (_.isNull obj) or (_.isUndefined obj)

    length = obj.length

    (length is 0) or ((_.isNumber length) and 
                      (length > 0) and 
                      `((length - 1) in obj)`)