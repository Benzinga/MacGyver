describe "Mac autocomplete", ->
  data             = {}
  $compile         = null
  $rootScope       = null
  $timeout         = null
  keys             = null
  $sniffer         = null
  changeInputValue = null

  beforeEach module("Mac")
  beforeEach module("template/autocomplete.html")
  beforeEach module("template/menu.html")

  beforeEach inject (_$compile_, _$rootScope_, _keys_, _$sniffer_, _$timeout_) ->
    $compile   = _$compile_
    $rootScope = _$rootScope_
    keys       = _keys_
    $sniffer   = _$sniffer_
    $timeout   = _$timeout_

    data = ["foo", "world", "bar"]

    changeInputValue = (element, value) ->
      element.val value
      element.trigger (if $sniffer.hasEvent("input") then "input" else "change")

  afterEach ->
    $(".mac-menu").remove()

  describe "Basic Initialization", ->
    it "should be compiled as text input", ->
      element = $compile("<mac-autocomplete ng-model='test'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      expect(element.is(":input[type='text']")).toBe true

    it "should throw an error if ng-model is not defined", ->
      init = ->
        element = $compile("<mac-autocomplete></mac-autocomplete>") $rootScope
        $rootScope.$digest()

      expect(init).toThrow()

    it "should not append menu", ->
      element = $compile("<mac-autocomplete ng-model='value'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      expect($(".mac-menu").length).toBe 0

  describe "source", ->
    $httpBackend = null

    beforeEach inject (_$httpBackend_) ->
      $httpBackend = _$httpBackend_

    it "should use local array", ->
      $rootScope.source = data
      $rootScope.test   = ""
      element           = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "fo"
      $rootScope.$digest()

      expect($(".mac-menu-item").text()).toBe "foo"

    it "should use local label, value object", ->
      $rootScope.source = [
        {name: "foo", value: "foo"}
        {name: "world", value: "world"}
        {name: "bar", value: "bar"}
      ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      expect($(".mac-menu-item").text()).toBe "foo"

    it "should use a url string and work exactly like mac-autocomplete-url", ->
      $httpBackend.when("GET", "/api/autocomplete?q=f").respond({data})

      $rootScope.source = "/api/autocomplete"

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      $httpBackend.flush()

    it "should use a callback function", ->
      $rootScope.source = (query, callback) -> callback ["foo"]

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      expect($(".mac-menu-item").text()).toBe "foo"

    it "should use a callback function returned by an invoked function", ->
      $rootScope.source = (val) ->
        return (query, callback) -> callback [val]

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source(\"foo\")' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      expect($(".mac-menu-item").text()).toBe "foo"

  describe "label", ->
    it "should use default 'name' label", ->
      $rootScope.source = [
        {name: "foo", value: "foo"}
        {name: "world", value: "world"}
        {name: "bar", value: "bar"}
      ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      expect($(".mac-menu-item").text()).toBe "foo"

    it "should not be able to find anything", ->
      $rootScope.source = [
        {key: "foo", value: "foo"}
        {key: "world", value: "world"}
        {key: "bar", value: "bar"}
      ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      expect($(".mac-menu-item").text()).not.toBe "foo"

    it "should use 'label' as the key", ->
      $rootScope.source = [
        {label: "foo", value: "foo"}
        {label: "world", value: "world"}
        {label: "bar", value: "bar"}
      ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-label='label' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      expect($(".mac-menu-item").text()).toBe "foo"

    it "should evaulate expression on label attribute correctly", ->
      $rootScope.source = [
        {
          name: "foo"
          attributes:
            value: "foo"
        }
      ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-label='attributes.value' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      expect($(".mac-menu-item").text()).toBe "foo"

  describe "updateItem", ->
    it "should convert key to label", ->
      $rootScope.source = (query, cb) ->
        cb [
          {key: "foo", value: "foo"}
          {key: "world", value: "world"}
          {key: "bar", value: "bar"}
        ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-label='key' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      items = $rootScope.$$childHead.items

      expect(items[0].label).toBeDefined()

    it "should keep all the parameters", ->
      $rootScope.source = (query, cb) ->
        cb [
          {key: "foo", value: "foo", param1: "1", param2: "2"}
          {key: "world", value: "world", param3: "3"}
          {key: "bar", value: "bar"}
        ]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-label='key' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      items = $rootScope.$$childHead.items

      expect(items[0].param1).toBe "1"
      expect(items[0].param2).toBe "2"

    it "should convert string to object", ->
      $rootScope.source = (query, cb) ->
        cb ["foo", "bar", "world"]
      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-label='key' mac-autocomplete-delay='0'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      items = $rootScope.$$childHead.items

      expect(items[0].label).toBe "foo"
      expect(items[0].value).toBe "foo"

  describe "options", ->
    it "should use default delay - 800ms", ->
      $rootScope.source = data

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      expect($(".mac-menu").hasClass "visible").toBeFalsy()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()

      expect($(".mac-menu").hasClass "visible").toBeTruthy()

    it "should delay for 200ms", ->
      $rootScope.source = data

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-delay='200'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      expect($(".mac-menu").hasClass "visible").toBeFalsy()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()

      expect($(".mac-menu").hasClass "visible").toBeTruthy()

    it "should disable autocomplete", ->
      $rootScope.disabled = true
      element             = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-disabled='disabled'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      expect($(".mac-menu").hasClass "visible").toBeFalsy()

      changeInputValue element, "f"
      $rootScope.$digest()

      expect($(".mac-menu").hasClass "visible").toBeFalsy()

  describe "callbacks", ->
    $httpBackend = null
    $timeout     = null

    beforeEach inject (_$httpBackend_, _$timeout_) ->
      $httpBackend = _$httpBackend_
      $timeout     = _$timeout_

    it "should call select", ->
      called            = false
      selectedItem      = ""
      $rootScope.source = data
      $rootScope.select = (selected) ->
        selectedItem = selected
        called       = true

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-autocomplete-on-select='select(selected)'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      runs ->
        changeInputValue element, "f"
        $rootScope.$digest()

        $timeout.flush()

        element.trigger $.Event("keydown", {which: keys.ENTER})

      waitsFor ->
        return called
      , "selected item", 200

      runs ->
        expect(selectedItem).toBe "foo"

    it "should call success", ->
      $httpBackend.when("GET", "/api/autocomplete?q=f").respond({data})

      result             = []
      $rootScope.url     = "/api/autocomplete"
      $rootScope.success = (data) ->
        result = data

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-url='url' mac-autocomplete-on-success='success(data)'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()
      $httpBackend.flush()

      expect(result.data.length).toBe 3

    it "should have three items in autocomplete list", ->
      $httpBackend.when("GET", "/api/autocomplete?q=f").respond({data})

      $rootScope.url     = "/api/autocomplete"
      $rootScope.success = (data) ->
        return data.data

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-url='url' mac-autocomplete-on-success='success(data)'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()
      $httpBackend.flush()

      expect($(".mac-menu-item").length).toBe 3

    it "should call error", ->
      $httpBackend.when("GET", "/api/404?q=f").respond(404)

      $rootScope.url   = "/api/404"
      $rootScope.error = jasmine.createSpy "error"

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-url='url' mac-autocomplete-on-error='error(data)'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()
      $httpBackend.flush()

      expect($rootScope.error).toHaveBeenCalled()

  describe "model -> view", ->
    it "should update the view", ->
      element = $compile("<mac-autocomplete ng-model='value'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      $rootScope.value = "hello"
      $rootScope.$digest()

      expect(element.val()).toBe "hello"

  describe "mac-menu class", ->
    it "should set classes", ->
      $rootScope.source  = data
      $rootScope.classes = {test: true, hello: false}

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source' mac-menu-class='classes'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()

      menuEl = $(".mac-menu")

      expect(menuEl.hasClass "test").toBeTruthy()
      expect(menuEl.hasClass "hello").toBeFalsy()

    it "should not have ng-class on menu element", ->
      $rootScope.source  = data

      element = $compile("<mac-autocomplete ng-model='test' mac-autocomplete-source='source'></mac-autocomplete>") $rootScope
      $rootScope.$digest()

      changeInputValue element, "f"
      $rootScope.$digest()

      $timeout.flush()

      menuEl = $(".mac-menu")
      expect(menuEl.attr("ng-class")).toBeFalsy()
