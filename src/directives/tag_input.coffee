##
## @name
## Tag Input
##
## @description
## A directive for generating tag input.
##
## @dependencies
## - Chosen
##
## @attributes
## - mac-tag-input-tags:        the list of elements to populate the select input
## - mac-tag-input-selected:    the list of elements selected by the user
## - mac-tag-input-placeholder: placeholder text for tag input                    (default "")
## - mac-tag-input-no-result:   custom text when there is no search result
## - mac-tag-input-value:       the value to be sent back upon selection          (default "id")
## - mac-tag-input-label:       the label to display to the users                 (default "name")
##

angular.module("Mac").directive "macTagInput", [
  "$rootScope",
  "$parse",
  ($rootScope, $parse) ->
    restrict:    "E"
    scope:
      selected: "=macTagInputSelected"
      items:    "=macTagInputTags"
    templateUrl: "template/tag_input.html"
    transclude:  true
    replace:     true

    compile: (element, attr) ->
      placeholder = attr.macTagInputPlaceholder or ""
      noResult    = attr.macTagInputNoResult
      valueKey    = attr.macTagInputValue       or "id"
      textKey     = attr.macTagInputLabel       or "name"
      options     = {}

      element.attr "data-placeholder", placeholder

      itemValueKey = if valueKey? then ".#{valueKey}" else ""
      itemTextKey  = if textKey?  then ".#{textKey}" else ""
      $("option", element).attr("value", "{{item#{itemValueKey}}}")
                          .text("{{item#{itemTextKey}}}")

      options.no_results_text = noResult if noResult?

      # initialize the element in compile
      # as initializing in link will break other directives
      chosenElement = element.chosen(options)

      ($scope, element, attr) ->
        #
        # @name updateTagInput
        # @description
        # To trigger an update on chosen and redraw the widget
        #
        updateTagInput = ->
          chosenElement.trigger "liszt:updated"

        #
        # @name updateSelectedOptions
        # @description
        # Add selected property to selected options
        #
        updateSelectedOptions = ->
          selectedValues = _($scope.selected).pluck valueKey
          $("option", element).each (i, e) ->
            $(e).prop("selected", "selected") if $(e).val() in selectedValues

        $scope.$on "update-tag-input", -> updateTagInput()

        $scope.$watch "items", ->
          setTimeout (->
            updateSelectedOptions()
            updateTagInput()
          ), 0

        # Called when user either add or remove a tag
        chosenElement.change (event, object)->
          $scope.$apply ->
            if object.selected?
              $scope.selected.push _($scope.items).find (item) ->
                                    (item[valueKey] or item) is object.selected
            else if object.deselected?
              $scope.selected = _($scope.selected).reject (item) ->
                                  (item[valueKey] or item) is object.deselected
]
