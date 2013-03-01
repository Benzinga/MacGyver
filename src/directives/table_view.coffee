##
## @name
## Table view
##
## @description
## A directive for generating a lazy rendered table
##
## @dependencies
## - jQuery UI Sortable
## - jQuery UI Resizable
##
## @variables
## {Object} row Each row data
## {Object} total An object with total value
##
## @attributes
## - mac-table-data:              Array of objects with table data
## - mac-table-total-data:        Object with total value
## - mac-table-columns:           Array of columns to display
## - mac-table-loading:           Boolean to indicate if table is loading data
##
## - mac-table-has-header:        A boolean value to determine if header should be shown           (default true)
## - mac-table-has-total-footer:  Boolean determining if footer with total should be shown         (default false)
## - mac-table-has-footer:        A boolean value to determine if footer should be shown           (default false)
## - mac-table-width:             The width of the whole table                                     (default 800)
## - mac-table-fluid-width:       When true, width of the table is 100% of the parent container    (default false)
## - mac-table-column-width:      The minimum width of a column                                    (default 140)
## - mac-table-header-height:     The height of the header row                                     (default mac-table-row-height)
## - mac-table-row-height:        The height of each row in the table                              (default 20)
## - mac-table-num-display-rows:  The total number of rows to display                              (default 10)
## - mac-table-cell-padding:      Should match the css padding value on each cell                  (default 8)
## - mac-table-border-width:      Should match the css border width value on each cell             (default 1)
## - mac-table-sortable:          Allow user to change the order of columns                        (default false)
## - mac-table-resizable:         Allow each column to be resized by the user                      (default false)
## - mac-table-lock-first-column: Lock first column to a static position                           (default false)
## - mac-table-allow-reorder:     Allow user to click on the header to reorder rows                (default true)
## - mac-table-object-prefix:     Useful when using backbone object where data is in attributes    (default "")
## - mac-table-calculate-total-locally: A boolean value to determine if total should be calculated (default false)
## - mac-table-auto-height:       Boolean value to determine if the height should readjust when
##                                the number of data rows is less than display rows                (default true)
## - mac-table-show-loader:       Boolean value to determine if loading spinner should be shown    (default true)
## - mac-table-empty-text:        Text to show when there is no data in table                      (default "No Data")
##
## @attributes (cell)
## - column:  Column name
## - style:   CSS style for the cell
## - class:   Class to use for the cell
##
## @attributes (header cell)
## - sort-by: The key to use for sorting for the column
##

angular.module("Mac").directive "macTable", [
  "$rootScope"
  "$compile"
  "$filter"
  "util"
  ($rootScope, $compile, $filter, util) ->
    restrict: "EA"
    scope:
      data:      "=macTableData"
      totalData: "=macTableTotalData"
      columns:   "=macTableColumns"
    replace:     true
    transclude:  true
    templateUrl: "template/table_view.html"

    compile: (element, attrs, transclude) ->
      # Default table view attributes
      defaults =
        hasHeader:             true
        hasTotalFooter:        false
        hasFooter:             false
        width:                 800
        columnWidth:           140
        headerHeight:          20
        rowHeight:             20
        numDisplayRows:        10
        cellPadding:           8
        borderWidth:           1
        sortable:              false
        resizable:             false
        lockFirstColumn:       false
        allowReorder:          true
        objectPrefix:          ""
        calculateTotalLocally: false
        fluidWidth:            false
        autoHeight:            true
        showLoader:            true

      transcludedBlock = $(".mac-table-transclude", element)
      headerBlock      = $(".mac-table-header", element)
      headerRow        = $(".mac-table-row", headerBlock)
      bodyWrapperBlock = $(".mac-table-body-wrapper", element)
      firstColumn      = $(".mac-title-column", bodyWrapperBlock)
      bodyBlock        = $(".mac-table-body", element)
      bodyHeightBlock  = $(".mac-table-body-height", element)
      footerBlock      = $(".mac-table-footer", element)
      totalRow         = $(".total-footer-row", footerBlock)
      customFooterRow  = $(".custom-footer-row", footerBlock)
      emptyCell        = $("<div>").addClass "mac-cell"

      # Calculate all the options based on defaults
      opts = util.extendAttributes "macTable", defaults, attrs

      # Default header height to row height if header height is not defined
      opts.headerHeight   = opts.rowHeight unless attrs.macTableHeaderHeight?

      # Total header should show if total is calculated locally
      opts.hasTotalFooter = opts.calculateTotalLocally if opts.calculateTotalLocally

      cellOuterHeight = opts.rowHeight + opts.cellPadding * 2

      ($scope, element, attrs) ->
        window.s = $scope

        # Get all the columns defined in the body template
        bodyTemplateCells = $(".table-body-template .cell", transcludedBlock)
        if bodyTemplateCells.length is 0
          throw "Missing cell templates"
        bodyColumns = bodyTemplateCells.map (i, item) ->
          return $(item).attr "column"

        #
        # @name render
        # @description
        # Called when data has been updated and require rendering
        #
        render = ->
          if $scope.data? and $scope.tableInitialized
            reOrderingRows()
            updateDisplayRows()

            # Recalculate total if data have changed
            $scope.calculateTotal() if opts.calculateTotalLocally

            $scope.calculateBodyDimension()

        # Update table when data changes
        $scope.$watch "data",        render
        $scope.$watch "data.length", render

        # Render table when all columns are set
        # Or when columns change
        $scope.$watch "columns", ->
          if $scope.columns?
            return               unless _($scope.columns).every()
            $scope.renderTable() unless $scope.tableInitialized

            calculateRowCss()

        $scope.$watch "predicate", (value) -> reOrderingRows() if value?
        $scope.$watch "reverse",   (value) -> reOrderingRows() if value?

        Object.defineProperty $scope, "total",
          get: ->
            totalKey = if opts.calculateTotalLocally then "localTotal" else "totalData"
            $scope[totalKey]

        #
        # @name reOrderingRows
        # @description
        # Used for reordering all the rows with predicate and reverse variable
        #
        reOrderingRows = ->
          data               = $scope.data or []
          $scope.orderedRows =
            if opts.allowReorder
               $filter("orderBy") data, $scope.predicate, $scope.reverse
            else
              data
          updateDisplayRows()

        #
        # @name updateDisplayRows
        # @description
        # Calculate the current scrolling offset and display the correct rows
        #
        updateDisplayRows = ->
          data               = $scope.orderedRows or []
          scrollTop          = bodyWrapperBlock.scrollTop()
          index              = Math.ceil scrollTop / cellOuterHeight
          endIndex           = index + opts.numDisplayRows - 1
          parent             = $scope.$parent
          $scope.displayRows = _(data[index..endIndex]).map (value) -> {value, parent}

        #
        # @name calculateColumnCss
        # @description
        # Calculate CSS attributes of all columns and store to $scope.columnCss
        # @return {Boolean} true
        #
        calculateColumnCss = ->
          for column in bodyColumns
            #Check if body cell has set width
            bodyCell = getTemplateCell "body", column
            setWidth = bodyCell.css "width"

            # Distinguish between percentage and pixels

            if (widthMatch = /(\d+)(px|%)?/.exec setWidth)?
              setWidth = +widthMatch[1]
              unit     = widthMatch[2]
            setWidth ?= 0

            if setWidth is 0
              # Calculate the relative width of each cell
              numColumns      = $scope.columns.length
              calculatedWidth = (opts.width / numColumns) - opts.cellPadding * 2 - opts.borderWidth

              # Use minimum width if the relative width is too small
              width = Math.max calculatedWidth, opts.columnWidth
            else
              # Convert percentage to real width
              setWidth = element.width() * (setWidth / 100) if unit is "%"
              width    = setWidth

            $scope.columnsCss[column] =
              "width":       width
              "padding":     opts.cellPadding
              "height":      opts.rowHeight
              "line-height": "#{opts.rowHeight}px"

          return true

        #
        # @name calculateRowCss
        # @description
        # Calculate the row width based on user defined columns
        # @return {Boolean} true
        #
        calculateRowCss = ->
          calculateRowWidth = 0
          startIndex = if opts.lockFirstColumn then 1 else 0
          for column in $scope.columns[startIndex..]
            continue unless column
            throw "Missing body template for cell '#{column}'" unless $scope.columnsCss[column]?
            calculateRowWidth += $scope.columnsCss[column].width + opts.cellPadding * 2 + opts.borderWidth
          $scope.rowCss = {width: calculateRowWidth}

          return true

        #
        # @name getTemplateCell
        # @description
        # Get the correct template cell transcluded block
        # @params {String} section Either header, body or footer (default "")
        # @params {String} column Column needed                  (default "")
        #
        getTemplateCell = (section = "", column = "") ->
          templateSelector = """.table-#{section}-template .cell[column="#{column}"]"""
          selected = $(templateSelector, transcludedBlock)
          if selected.length > 1
            throw "More than 1 definition of '#{column}' in '#{section}' section"
            selected = selected.first()
          return selected

        #
        # @name createCellTemplate
        # @description
        # Get the template cell user has defined in template, create empty cell if not found
        # The width and height will be calculated and set before returning
        #
        # @params {String} section Either header, body or footer (default "")
        # @params {String} column Column needed                  (default "")
        #
        createCellTemplate = (section="", column="") ->
          return {cell: $("<div>"), width: 0} unless column
          cell = getTemplateCell(section, column).clone()
          cell = emptyCell.clone() if cell.length is 0

          # Set column property again
          cell.prop("column", column).addClass "mac-cell"

          unless $scope.columnsCss[column]? and cell?
            throw "Missing body template for cell '#{column}'"
          width = $scope.columnsCss[column].width + 2 * opts.cellPadding + opts.borderWidth

          return {cell, width}

        #
        # @name createHeaderCellTemplate
        # @description
        # This is a shortcut call for header version of createCellTemplate
        # Caret is added to the cell before returning
        # @params {String} column Column needed (default "")
        #
        createHeaderCellTemplate = (column = "", firstColumn = false) ->
          {cell, width} = createCellTemplate "header", column
          contextText   = cell.html()

          parentScope  = if firstColumn then "" else "$parent.$parent."

          # Check for user defined sort-by attribute
          sortBy  = cell.attr "sort-by"
          sortBy ?= column.toLowerCase()

          cellClass  = """mac-table-caret {{#{parentScope}reverse | boolean:"up":"down"}} """
          cellClass += """{{#{parentScope}predicate == "#{sortBy}" | false:'hide'}}"""

          cell.text column if contextText.length is 0

          # Enable reordering
          if opts.allowReorder
            cell.attr "ng-click", "orderBy('#{sortBy}')"
            cell.addClass "reorderable"

          cell
            .attr("for", column)
            .append $("<span>").attr "class", cellClass

          return {cell, width}

        #
        # @name createRowTemplate
        # @description
        # Create template row with switches to select the correct column template
        # @params {String} section Table section
        # @return {jQuery Element} template row
        #
        createRowTemplate = (section="", isFirst = false) ->
          rowWidth   = 0
          startIndex = if opts.lockFirstColumn then 1 else 0

          # Create template cell with ng-repeat and ng-switch
          cssClass  = "mac-table-#{section}-cell"
          cssClass += " mac-table-cell" unless section is "header"

          # Only repeat columns when the row template is not generated for first column
          if isFirst
            row = $("<div>").attr
              "ng-switch":   "columns[0]"
              "ng-style":    "getColumnCss(columns[0], '#{section}')"
              "data-column": "{{columns[0]}}"
          else
            row = $("<div>").attr
              "ng-switch":   "column"
              "ng-repeat":   "column in columns.slice(#{startIndex})"
              "ng-style":    "getColumnCss(column, '#{section}')"
              "data-column": "{{column}}"

          row.addClass cssClass

          for column in bodyColumns
            {cell, width} = if section is "header"
                              createHeaderCellTemplate column
                            else
                              createCellTemplate section, column
            cell.attr "ng-switch-when", column
            row.append cell

            rowWidth += width

          return {row, width: rowWidth}

        #
        # @name $scope.getColumnCss
        # @description
        # A get function for getting CSS object
        # @params {String} column Column name
        # @params {String} section Section for the css
        # @params {Boolean} isFirst First column or not
        # @return {Object} Object with CSS attributes
        #
        $scope.getColumnCss = (column, section) ->
          return {} unless column and column?

          unless $scope.columnsCss[column]?
            # TODO: Better error message
            #throw "Missing body template for cell '#{column}'"
            return {}

          css        = angular.copy $scope.columnsCss[column]
          css.height = opts.headerHeight if section is "header"

          return css

        #
        # @name $scope.getBodyBlockCss
        # @description
        # Get the css for the body section
        # @params {String} section Section of the body
        # @return {Object} Object with CSS properties
        #
        $scope.getBodyBlockCss = (section="body") ->
          width   = $scope.getColumnCss($scope.columns[0], "body").width or 0
          width  += 2 * opts.cellPadding if width > 0
          isFirst = opts.lockFirstColumn
          if isFirst and width?
            switch section
              when "total-footer"
                "padding-left": width
              else
                "margin-left": width
                width:         element.width() - width
          else
            {}

        #
        # @name $scope.getTableCss
        # @description
        # Get table height and width styling
        # @return {Object} Object with height and width
        #
        $scope.getTableCss = ->
          dataLength      = $scope.data?.length or 0
          totalRows       = if dataLength is 0 or not opts.autoHeight
                              opts.numDisplayRows
                            else
                              Math.min dataLength, opts.numDisplayRows
          totalRows      += opts.hasFooter + opts.hasTotalFooter
          elementHeight   = cellOuterHeight * totalRows
          elementHeight  += opts.hasHeader * (opts.headerHeight + 2 * opts.cellPadding + opts.borderWidth)
          elementHeight  += 2 * opts.borderWidth

          # Update the width and height of the whole table
          width = if opts.fluidWidth then "100%" else (opts.width - 2 * opts.borderWidth)

          return {
            height: elementHeight
            width:  width
          }

        #
        # @name $scope.orderBy
        # @description
        # Function to call when user click on header cell
        # $scope.predicate and $scope.reverse
        # @params {jQuery Object} column The element to bind click event to
        #
        $scope.orderBy = (column) ->
          columnTitle = column.toLowerCase()
          if opts.objectPrefix
            columnTitle = opts.objectPrefix + "." + columnTitle

          if columnTitle is $scope.predicate
            $scope.reverse = not $scope.reverse
          else
            $scope.predicate = columnTitle
            $scope.reverse   = false

        #
        # @name $scope.calculateTotal
        # @description
        # Caclculate the total for each column of all rows and store in total
        #
        $scope.calculateTotal = ->
          $scope.localTotal = _($scope.data).reduce (memo, row) ->
            row = row[opts.objectPrefix] if opts.objectPrefix
            for key, value of row
              memo[key] ?= 0
              memo[key] += if isNaN(value) then 0 else +value
            return memo
          , {}

        #
        # @name $scope.drawHeader
        # @description
        # Create table header.
        # A separate header cell is created if first column is locked
        # Enabling order by, resizable columns and drag and drop columns
        #
        $scope.drawHeader = ->
          {row, width} = createRowTemplate "header"

          # TODO: Enable column resizing
          if opts.resizable
            row.resizable
              containment: "parent"
              minHeight:   opts.rowHeight
              maxHeight:   opts.rowHeight
              handles:     "e, w"
            .addClass "resizable"

          # Set the header to be the width of all columns
          headerRow.append(row).attr
            "ng-style": "rowCss"

          # Compile the column to render carets
          $compile(headerRow) $scope

          # Create a separate cell if the first cell is locked
          if opts.lockFirstColumn
            {row, width} = createRowTemplate "header", true
            row.addClass("mac-cell mac-table-locked-cell mac-table-header-cell").attr
              "ng-style": "getColumnCss(columns[0], 'header')"

            cellWidth  = $scope.getColumnCss($scope.columns[0], "header").width or 0
            cellWidth += 2 * opts.cellPadding if cellWidth > 0

            headerRow.css "margin-left", cellWidth

            headerBlock.append row

            # Compile the column to render carets
            $compile(headerBlock) $scope

          # Enable drag and drop on header cell
          if opts.sortable
            headerRow.sortable
              items:       "> .mac-table-header-cell"
              cursor:      "move"
              opacity:     0.8
              tolerance:   "pointer"
              update:      (event, ui) ->
                newOrder = []
                $(".mac-table-header-cell", headerRow).each (i, e) ->
                  newOrder.push $(e).data "column"

                # First column is locked and need to be readded back to new column order
                if opts.lockFirstColumn and $scope.columns.length > 0
                  newOrder.unshift $scope.columns[0]

                $scope.$apply -> $scope.columns = newOrder

                setTimeout (->
                  bodyBlock.scrollLeft headerBlock.scrollLeft()
                ), 0

        #
        # @name $scope.drawTotalFooter
        # @description
        # To create the footer with total value of the table
        #
        $scope.drawTotalFooter = ->
          {row, width} = createRowTemplate "total-footer"

          # Set the header to be the width of all columns
          totalRow.append(row).attr "ng-style", "rowCss"

          if opts.lockFirstColumn
            {row, width} = createRowTemplate "total-footer", true

            row.addClass("mac-cell mac-table-locked-cell").attr
              "ng-style": "getColumnCss(columns[0], 'total-footer')"
            totalRow.prepend row

          # Compile the column to render carets
          $compile(totalRow) $scope

        #
        # @name $scope.drawFooter
        # @description
        # To create custom footer of the table
        #
        $scope.drawFooter = ->
          footerTemplate = $(".table-footer-template", transcludedBlock)
          customFooterRow.html(footerTemplate.html()).css
            "height":  opts.rowHeight
            "padding": opts.cellPadding
          $compile(customFooterRow) $scope

        #
        # @name $scope.calculateBodyDimension
        # @description
        # Calculate the height and the scrolling height of the table
        #
        $scope.calculateBodyDimension = ->
          data = $scope.data or []

          # Calculate the height to display scrollbar correctly
          bodyHeightBlock.height data.length * cellOuterHeight

          setTimeout ( ->
            dataLength = $scope.data?.length or 0
            numRows    = if dataLength is 0 or not opts.autoHeight
                           opts.numDisplayRows
                         else
                           Math.min dataLength, opts.numDisplayRows
            wrapperHeight = numRows * cellOuterHeight

            # Check if x-axis scrollbar exist
            if bodyBlock[0].scrollWidth > bodyBlock.width()
              wrapperHeight += 10
              element.height element.height() + 10 - 2 * opts.borderWidth

            bodyWrapperBlock.height wrapperHeight
            firstColumn.height wrapperHeight if opts.lockFirstColumn
          ), 0

        #
        # @name $scope.drawBody
        # @description
        # Create table body with 2 ng-repeats
        # One ng-repeat to render all the rows dispalyed based on the height
        # Another ng-repeat to render all the columns correctly and to redraw when the order change
        # Create a separate column if first column is locked with a ng-repeat
        #
        $scope.drawBody = ->
          data         = $scope.orderedRows or []
          extraClasses = ""

          # Check if row template exist
          rowTemplates = $(".table-body-template .mac-table-row", transcludedBlock)
          if rowTemplates.length > 0
            rowTemplate  = $(rowTemplates[0]).removeClass "mac-table-row"
            extraClasses = rowTemplate.attr("class")

          # Create template row with ng-repeat
          tableRow = $("<div>").addClass "mac-table-row {{$index % 2 | boolean:'odd':'even'}}"
          tableRow.attr
            "ng-repeat": "row in displayRows"
            "ng-cloak":  "ng-cloak"

          {row, width} = createRowTemplate "body"

          tableRow.append(row).attr "ng-style", "rowCss"

          # Set table row classes
          origClasses = tableRow.attr "class"
          tableRow.attr "class", [origClasses, extraClasses].join " "

          bodyBlock.append tableRow

          # Compile the body block to bind all values correctly
          $compile(bodyBlock) $scope

          # if the first column is locked, create a separate column with
          # fixed position
          if opts.lockFirstColumn
            fcTableRow    = $(".mac-table-row", firstColumn)
            {row, width}  = createRowTemplate "body", true

            fcTableRow.attr("ng-repeat", "row in displayRows")
                      .addClass("{{$index % 2 | boolean:'odd':'even'}}")
                      .append row

            # Set first column classes
            origClasses = fcTableRow.attr "class"
            fcTableRow.attr "class", [origClasses, extraClasses].join " "

            # Compile the column to render ng-repeat
            $compile(firstColumn) $scope

        # Up and down scrolling
        bodyWrapperBlock.scroll ->
          $this     = $(this)
          scrollTop = $this.scrollTop()

          # Fix the table at the same position
          bodyBlock.css "top", scrollTop
          firstColumn.css "top", scrollTop if opts.lockFirstColumn

          $scope.$apply -> updateDisplayRows()

        # Left and right scrolling
        bodyBlock.scroll ->
          $this      = $(this)
          scrollLeft = $this.scrollLeft()

          headerBlock.scrollLeft scrollLeft if opts.hasHeader
          footerBlock.scrollLeft scrollLeft if opts.hasFooter

        #
        # @name $scope.renderTable
        # @description
        # Function tto draw all components of the table
        # @return {Boolean} true
        #
        $scope.renderTable = ->
          # Set all required variables
          objectPrefix     = if opts.objectPrefix then "#{opts.objectPrefix}." else ""
          $scope.predicate =  if $scope.columns?.length > 0
                                "#{objectPrefix}#{$scope.columns[0].toLowerCase()}"
                              else
                                ""
          $scope.orderedRows = $scope.data

          # Calculate each columns styling
          calculateColumnCss()

          $scope.drawHeader() if opts.hasHeader

          $scope.drawBody()

          # Only calculate total value if footer exist
          $scope.calculateTotal() if opts.calculateTotalLocally

          $scope.drawTotalFooter() if opts.hasTotalFooter
          $scope.drawFooter()      if opts.hasFooter

          $scope.calculateBodyDimension()

          # Update body width if the table is fluid
          if opts.fluidWidth
            clearTimeout $scope.bodyBlockTimeout if $scope.bodyBlockTimeout?
            $scope.bodyBlockTimeout = setInterval (->
                leftMargin = bodyBlock.css "margin-left"
                bodyBlock.width element.width() - parseInt(leftMargin)
              ), 500

          updateDisplayRows()

          $scope.tableInitialized = true

          return true

        #
        # @name $scope.reset
        # @description
        # Reset table view scope
        #
        $scope.reset = ->
          $scope.orderedRows      = []
          $scope.displayRows      = []
          $scope.index            = 0
          $scope.columnsCss       = {}
          $scope.bodyBlockTimeout = null
          $scope.opts             = opts

          $scope.rowCss = {}

          # Use to determine if table has been initialized
          $scope.tableInitialized = false

          $scope.predicate = ""
          $scope.reverse   = false

        $scope.reset()
]
