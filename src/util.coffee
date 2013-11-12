##
## Util module
##
## Contains various miscellaneous utility functions and extensions.
##

# Expose an object with a bunch of utility functions on it.
angular.module("Mac.Util", []).factory "util", [
  "$filter"
  (
    $filter
  ) ->
    _inflectionConstants:
      uncountables: [
        "sheep", "fish", "moose", "series", "species", "money", "rice", "information", "info", "equipment", "min"
      ]

      irregulars:
        child:  "children"
        man:    "men"
        woman:  "women"
        person: "people"
        ox:     "oxen"
        goose:  "geese"

      pluralizers: [
        [/(quiz)$/i,                 "$1zes"  ]
        [/([m|l])ouse$/i,            "$1ice"  ]
        [/(matr|vert|ind)(ix|ex)$/i, "$1ices" ]
        [/(x|ch|ss|sh)$/i,           "$1es"   ]
        [/([^aeiouy]|qu)y$/i,        "$1ies"  ]
        [/(?:([^f])fe|([lr])f)$/i,   "$1$2ves"]
        [/sis$/i,                    "ses"    ]
        [/([ti])um$/i,               "$1a"    ]
        [/(buffal|tomat)o$/i,        "$1oes"  ]
        [/(bu)s$/i,                  "$1ses"  ]
        [/(alias|status)$/i,         "$1es"   ]
        [/(octop|vir)us$/i,          "$1i"    ]
        [/(ax|test)is$/i,            "$1es"   ]
        [/x$/i,                      "xes"    ]
        [/s$/i,                      "s"      ]
        [/$/,                        "s"      ]
      ]

    ###
    @name pluralize
    @description
    Pluralize string based on the count

    @param {String}  string       String to pluralize (default "")
    @param {Integer} count        Object counts
    @param {Boolean} includeCount Include the number or not (default false)

    @returns {String} Pluralized string based on the count
    ###
    pluralize: (string = "", count, includeCount = false) ->
      # If our string has no length, return without further processing
      return string if not angular.isString(string) or string.trim().length is 0

      # If the user is expecting count to be anything other
      # than the default, check if it is actually a number
      # If not, return an empty string
      if includeCount and isNaN +count
        return ""

      # Manually set our default here
      count = 2 unless count?

      {pluralizers, uncountables, irregulars} = @_inflectionConstants

      word           = string.split(/\s/).pop()
      isUppercase    = word.toUpperCase() is word
      lowercaseWord  = word.toLowerCase()
      pluralizedWord = if count is 1 or uncountables.indexOf(lowercaseWord) >= 0 then word else null

      unless pluralizedWord?
        pluralizedWord = irregulars[lowercaseWord] if irregulars[lowercaseWord]?

      unless pluralizedWord?
        for pluralizer in pluralizers when pluralizer[0].test lowercaseWord
          pluralizedWord = word.replace pluralizer[0], pluralizer[1]
          break

      pluralizedWord or = word
      pluralizedWord    = pluralizedWord.toUpperCase() if isUppercase
      pluralizedString  = string[0...-word.length] + pluralizedWord
      if includeCount then "#{$filter("number") count} #{pluralizedString}" else pluralizedString

    capitalize: (string) ->
      str = String(string) or ""
      return str.charAt(0).toUpperCase() + str.substring(1)
    uncapitalize: (string) ->
      str = String(string) or ""
      return str.charAt(0).toLowerCase() + str.substring(1)
    toCamelCase: (string =  "") ->
      string.trim().replace /[-_\s]+(.)?/g, (match, c) -> c.toUpperCase()
    toSnakeCase: (string = "") ->
      string.trim().
        replace(/([a-z\d])([A-Z]+)/g, "$1_$2").
        replace(/[-\s]+/g, "_").
        toLowerCase()

    convertKeysToCamelCase: (object) ->
      result = {}

      for own key, value of object
        key         = @toCamelCase key
        value       = @convertKeysToCamelCase value if typeof value is "object" and value?.constructor isnt Array
        result[key] = value

      result

    convertKeysToSnakeCase: (object) ->
      result = {}

      for own key, value of object
        key         = @toSnakeCase key
        value       = @convertKeysToSnakeCase value if typeof value is "object" and value?.constructor isnt Array
        result[key] = value

      result

    pyth:    (a,b)    -> Math.sqrt a*a + b*b
    degrees: (radian) -> (radian * 180) / Math.PI
    radian:  (degrees) -> (degrees * Math.PI) / 180

    hex2rgb: (hex) ->
      hex = hex.substring(1) if hex.indexOf('#') is 0
      hex = hex.toLowerCase()
      rgb = {}

      if hex.length is 3
        rgb.r = hex.charAt(0) + hex.charAt(0)
        rgb.g = hex.charAt(1) + hex.charAt(1)
        rgb.b = hex.charAt(2) + hex.charAt(2)
      else
        rgb.r = hex.substring(0, 2)
        rgb.g = hex.substring(2, 4)
        rgb.b = hex.substring(4)

      for color, value of rgb
        rgb[color] = parseInt value, 16

      return rgb

    #
    # @name timeRegex
    # @example
    # 01:30 PM or 9:45 AM
    #
    timeRegex: ///
      ^
      (0?[1-9]|1[0-2])  # hours (starting zero optional)
      :                 # colon
      ([0-5][0-9])      # minute
      [\s]              # space
      ([AP]M)           # meridian
      $
    ///

    # http://tools.ietf.org/html/rfc3986#section-2.2
    _urlRegex: ///
      (?:
        (http[s]?):// # protocol (optional)
      )?
      (?:
        (www|[\d\w\-]+)\. # subdomain (optional)
      )?
      ([\d\w\-]+)\.       # domain
      ([A-Za-z]{2,6})     # tld
      (:[\d]*)?           # port (optional)
      ([                  # path (optional)
        :/?#\[\]@         # rfc3986 gen-delims
        !$&'()*+,;=       # rfc3986 sub-delims
        \w\d-._~          # rfc3986 unreserved characters
        %\\               # additional characters
      ]*)?
    ///i

    _emailRegex: /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/

    validateUrl: (url) ->
      match = @_urlRegex.exec url
      if match?
        match = {
          url:        match[0]
          protocol:   match[1] or "http"
          subdomain:  match[2]
          name:       match[3]
          domain:     match[4]
          port:       match[5]
          path:       match[6] or "/"
        }
        # Recreate the full url
        match["url"] = match.url
      match

    validateEmail: (email) -> @_emailRegex.test email

    # credits: http://www.netlobo.com/url_query_string_javascript.html
    getQueryString: (url, name = "") ->
      name    = name.replace(/[[]/,"\[").replace(/[]]/,"\]")
      regexS  = "[\?&]"+name+"=([^&#]*)"
      regex   = new RegExp regexS
      results = regex.exec url
      if results? then results[1] else ""

    parseUrlPath: (fullPath) ->
      urlComponents  = fullPath.split "?"
      pathComponents = urlComponents[0].split("/")
      path           = pathComponents[0...pathComponents.length-1].join("/")
      verb           = pathComponents[pathComponents.length-1]
      queries        = {}

      # Check if querystring exists
      if urlComponents.length > 1
        queryStrings = urlComponents[urlComponents.length-1]
        for queryString in queryStrings.split("&")
          values = queryString.split "="
          queries[values[0]] = if values[1]? then values[1] else ""

      return {fullPath, path, pathComponents, verb, queries}

    ##
    ## @name
    ## extendAttributes
    ##
    ## @description
    ## Extend default values with attributes
    ##
    ## @param {String} prefix Prefix of all attributes
    ## @param {Object} defaults Default set of attributes
    ## @param {Object} attributes User set attributes
    ##
    extendAttributes: (prefix = "", defaults, attributes) ->
      output = {}
      for own key, value of defaults
        altKey      =  if prefix then @capitalize(key) else key
        macKey      = "#{prefix}#{altKey}"
        output[key] =
          if attributes[macKey]?
            attributes[macKey] or true
          else
            value

        # Convert to true boolean if passing in boolean string
        if output[key] in ["true", "false"]
          output[key] = output[key] is "true"
        # Convert to integer or numbers from strings
        else if output[key]?.length > 0 and not isNaN +output[key]
          output[key] = +output[key]

      return output
]



