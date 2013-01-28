##
## Tag Autocomplete
##
## A directive for generating tag input with autocomplete support on text input
##
## Attributes
## - mac-tag
##

angular.module("Mac").directive "macTagAutocomplete", [
  "$parse",
  "$http",
  "keys",
  ($parse, $http, key) ->
    restrict:    "E"
    scope:       {}
    templateUrl: "template/tag_autocomplete.html"
    replace:     true

    compile: (element, attr) ->
      urlExp      = attr.macTagAutocompleteUrl
      modelExp    = attr.macTagAutocompleteLocalModel
      valueKey    = attr.macTagAutocompleteValue
      labelKey    = attr.macTagAutocompleteLabel
      selectedExp = attr.macTagAutocompleteSelected
      queryKey    = attr.macTagAutocompleteQuery      or "q"
      delay       = attr.macTagAutocompleteDelay      or 100

      getUrl      = $parse urlExp
      getSelected = $parse selectedExp

      textInput = $(".text-input", element)

      # Update template on label variable name
      tagLabelKey = if labelKey? then ".#{labelKey}" else ""
      $(".tag-label", element).text "{{tag#{tagLabelKey}}}"

      ($scope, element, attrs) ->
        # Getting autocomplete url from parent scope
        Object.defineProperty $scope, "autocompleteUrl",
          get:       -> getUrl $scope.$parent
          set: (url) -> getUrl.assign $scope.$parent, url

        $scope.removeTag = (tag) ->
          index = $scope.tags.indexOf tag
          $scope.tags[index..index] = []
          $scope.updateSelectedArrary()

        # function to update array on parent scope with tag value
        $scope.updateSelectedArrary = ->
          outputTags = _($scope.tags).map (item, i) -> if valueKey? then item[valueKey] else item
          getSelected.assign $scope.$parent, outputTags

        textInput.bind "keydown", (event) ->
          stroke = event.which or event.keyCode
          switch stroke
            when key.BACKSPACE
              if $(this).val().length is 0
                $scope.$apply ->
                  $scope.tags.pop()
                  $scope.updateSelectedArrary()
          return true

        textInput.autocomplete
          delay:     delay
          autoFocus: true
          source: (req, resp) ->
            options =
              method: "GET"
              url:    $scope.autocompleteUrl
              params: {}
            options.params[queryKey] = req.term

            $http(options)
              .success (data, status, headers, config) ->
                # get all selected values
                existingValues = _($scope.tags).pluck valueKey
                # remove selected tags on autocomplete dropdown
                list           = _(data.data).reject (item) -> (item[valueKey] or item) in existingValues
                # convert tags to jquery ui autocomplete format
                resp _(list).map (item) ->
                  label = value = if labelKey? then item[labelKey] else item
                  return {label, value}
                # store the current data for revert lookup
                $scope.currentAutocomplete = data.data

          select: (event, ui) ->
            $scope.$apply ->
              item = _($scope.currentAutocomplete).find (item) -> item[labelKey] is ui.item.label
              $scope.tags.push item
              $scope.updateSelectedArrary()

            setTimeout (->
              textInput.val ""
            ), 0

        $scope.reset = ->
          $scope.tags                = []
          $scope.currentAutocomplete = []

        $scope.reset()
]
